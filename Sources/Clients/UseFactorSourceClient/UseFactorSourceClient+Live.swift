import ClientPrelude
import Profile
import SecureStorageClient

// MARK: - UseFactorSourceClient + DependencyKey
extension UseFactorSourceClient: DependencyKey {
	public typealias Value = Self

	public static let liveValue: Self = .init(
		publicKeyFromOnDeviceHD: { request in
			let privateKey = try request.hdRoot.derivePrivateKey(
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
			return try privateKey.sign(data: request.data)
		}
	)
}

import Cryptography
extension UseFactorSourceClient {
	public enum Purpose: Sendable, Equatable {
		case signData(Data, isTransaction: Bool)
		case createAccount
		case createPersona
		public static func createEntity(kind: EntityKind) -> Self {
			switch kind {
			case .identity: return .createPersona
			case .account: return .createAccount
			}
		}

		fileprivate var loadMnemonicPurpose: SecureStorageClient.LoadMnemonicPurpose {
			switch self {
			case let .signData(_, isTransaction): return isTransaction ? .signTransaction : .signAuthChallenge
			case .createAccount: return .createAccount
			case .createPersona: return .createPersona
			}
		}
	}

	// FIXME: temporary only
	public func onDeviceHD(
		factorSourceID: FactorSource.ID,
		derivationPath: DerivationPath,
		curve: Slip10Curve,
		purpose: Purpose
	) async throws -> (publicKey: Engine.PublicKey, signature: SignatureWithPublicKey?) {
		@Dependency(\.secureStorageClient) var secureStorageClient

		guard let loadedMnemonicWithPassphrase = try await secureStorageClient
			.loadMnemonicByFactorSourceID(factorSourceID, purpose.loadMnemonicPurpose)
		else {
			struct FailedToFindFactorSource: Swift.Error {}
			throw FailedToFindFactorSource()
		}
		let hdRoot = try loadedMnemonicWithPassphrase.hdRoot()

		if case let .signData(dataToSign, _) = purpose {
			let result = try self.signatureFromOnDeviceHD(.init(hdRoot: hdRoot, derivationPath: derivationPath, curve: curve, data: dataToSign))
			return try (publicKey: result.publicKey.intoEngine(), signature: result)
		} else {
			return try (publicKey: self.publicKeyFromOnDeviceHD(.init(hdRoot: hdRoot, derivationPath: derivationPath, curve: curve)), signature: nil)
		}
	}
}
