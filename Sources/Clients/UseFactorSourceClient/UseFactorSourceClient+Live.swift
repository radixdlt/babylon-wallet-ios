import ClientPrelude
import EngineToolkit
import Profile
import SecureStorageClient

// MARK: - FailedToFindFactorSource
struct FailedToFindFactorSource: Swift.Error {}

// MARK: - UseFactorSourceClient + DependencyKey
extension UseFactorSourceClient: DependencyKey {
	public typealias Value = Self

	public static let liveValue: Self = {
		@Dependency(\.secureStorageClient) var secureStorageClient

		return Self(
			publicKeyFromOnDeviceHD: { request in
				let factorSourceID = request.hdOnDeviceFactorSource.id

				guard
					let mnemonicWithPassphrase = try await secureStorageClient
					.loadMnemonicByFactorSourceID(factorSourceID, .createEntity(kind: request.entityKind))
				else {
					loggerGlobal.critical("Failed to find factor source with ID: '\(factorSourceID)'")
					throw FailedToFindFactorSource()
				}
				let hdRoot = try mnemonicWithPassphrase.hdRoot()
				let privateKey = try hdRoot.derivePrivateKey(
					path: request.derivationPath,
					curve: request.curve
				)

				return try privateKey.publicKey().intoEngine()
			},
			signatureFromOnDeviceHD: { request in
				let privateKey = try request.hdRoot.derivePrivateKey(
					path: request.derivationPath,
					curve: request.curve
				)
				let hashedData = try blake2b(data: request.unhashedData)
				return try privateKey.sign(unhashed: request.unhashedData, hashOfMessage: hashedData)
			}
		)
	}()
}

import Cryptography

// MARK: - UseFactorSourceClient.Purpose
extension UseFactorSourceClient {
	public enum Purpose: Sendable, Equatable {
		case signData(Data, isTransaction: Bool)
		case createEntity(kind: EntityKind)
		fileprivate var loadMnemonicPurpose: SecureStorageClient.LoadMnemonicPurpose {
			switch self {
			case let .signData(_, isTransaction): return isTransaction ? .signTransaction : .signAuthChallenge
			case let .createEntity(kind): return .createEntity(kind: kind)
			}
		}
	}
}
