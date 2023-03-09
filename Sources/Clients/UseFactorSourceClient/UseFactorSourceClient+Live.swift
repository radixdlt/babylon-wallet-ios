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
			let signature = try privateKey.sign(data: request.data)
			switch signature.signature {
			case .eddsaEd25519: print("❌ Curve25519 sig..")
			case .ecdsaSecp256k1: print("🔮 ECDSA sig! nice!")
			}
			print("🔮 successfully signed: \(signature)")
			print("🔮 is valid sig?: \(signature.publicKey.isValidSignature(signature.signature, for: request.data))")

			return signature
		}
	)
}

import Cryptography
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
