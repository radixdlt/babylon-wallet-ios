import CryptoKit
import Foundation
import K1

// MARK: - SignatureWithPublicKey
public enum SignatureWithPublicKey: Sendable, Hashable, CustomDebugStringConvertible {
	case ecdsaSecp256k1(
		signature: ECDSASignatureRecoverable,
		publicKey: K1.PublicKey
	)

	case eddsaEd25519(
		signature: EdDSASignature,
		publicKey: Curve25519.Signing.PublicKey
	)
}

extension SignatureWithPublicKey {
	public var signature: SLIP10.Signature {
		switch self {
		case let .eddsaEd25519(signature, _):
			return .eddsaEd25519(signature)
		case let .ecdsaSecp256k1(signature, _):
			return .ecdsaSecp256k1(signature)
		}
	}

	public var publicKey: SLIP10.PublicKey {
		switch self {
		case let .eddsaEd25519(_, publicKey):
			return .eddsaEd25519(publicKey)
		case let .ecdsaSecp256k1(_, publicKey):
			return .ecdsaSecp256k1(publicKey)
		}
	}

	public func isValidSignature(for hashed: Data) -> Bool {
		switch self {
		case let .ecdsaSecp256k1(signature, publicKey):
			do {
				return try publicKey.isValid(signature: signature, hashed: hashed)
			} catch { return false }
		case let .eddsaEd25519(signature, publicKey):
			return publicKey.isValidSignature(signature, for: hashed)
		}
	}

	public var debugDescription: String {
		do {
			switch self {
			case let .ecdsaSecp256k1(signature, publicKey):
				return try "Secp256k1 PublicKey: \(publicKey.compressedRepresentation.hex), ECDSA sig: \(signature.radixSerialize().hex)"
			case let .eddsaEd25519(signature, publicKey):
				return "Curve25519 PublicKey: \(publicKey.rawRepresentation.hex), EdDSA sig: \(signature.hex)"
			}
		} catch {
			return "failed to serialize publicKey with signature"
		}
	}
}
