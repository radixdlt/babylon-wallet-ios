import ClientPrelude
import EngineToolkit
import Profile
import SecureStorageClient

// MARK: - FailedToFindFactorSource
struct FailedToFindFactorSource: Swift.Error {}

// MARK: - DeviceFactorSourceClient + DependencyKey
extension DeviceFactorSourceClient: DependencyKey {
	public typealias Value = Self

	public static let liveValue: Self = {
		@Dependency(\.secureStorageClient) var secureStorageClient

		return Self(
			publicKeyFromOnDeviceHD: { request in
				let factorSourceID = request.hdOnDeviceFactorSource.id

				guard
					let mnemonicWithPassphrase = try await secureStorageClient
					.loadMnemonicByFactorSourceID(factorSourceID, request.loadMnemonicPurpose)
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
				return try privateKey.sign(hashOfMessage: hashedData)
			}
		)
	}()
}

import Cryptography
