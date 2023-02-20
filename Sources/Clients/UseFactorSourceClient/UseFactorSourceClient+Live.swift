import ClientPrelude
import Profile

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
	// FIXME: temporary only
	public func onDeviceHD(
		factorSourceID: FactorSource.ID,
		keychainAccessFactorSourcesAuthPrompt: String,
		derivationPath: DerivationPath,
		curve: Slip10Curve,
		dataToSign: Data? = nil
	) async throws -> (publicKey: Engine.PublicKey, signature: SignatureWithPublicKey?) {
		@Dependency(\.keychainClient) var keychainClient

		guard let loadedMnemonicWithPassphrase = try await keychainClient.loadFactorSourceMnemonicWithPassphrase(
			factorSourceID: factorSourceID,
			authenticationPrompt: keychainAccessFactorSourcesAuthPrompt
		) else {
			struct FailedToFindFactorSource: Swift.Error {}
			throw FailedToFindFactorSource()
		}
		let hdRoot = try loadedMnemonicWithPassphrase.hdRoot()

		if let dataToSign {
			let result = try self.signatureFromOnDeviceHD(.init(hdRoot: hdRoot, derivationPath: derivationPath, curve: curve, data: dataToSign))
			return try (publicKey: result.publicKey.intoEngine(), signature: result)
		} else {
			return try (publicKey: self.publicKeyFromOnDeviceHD(.init(hdRoot: hdRoot, derivationPath: derivationPath, curve: curve)), signature: nil)
		}
	}
}
