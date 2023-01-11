import CryptoKit
import Foundation
import K1

// MARK: - SignatureWithPublicKey
public enum SignatureWithPublicKey: Sendable, Hashable {
	case ecdsaSecp256k1(
		signature: ECDSASignatureRecoverable,
		publicKey: K1.PublicKey
	)

	case eddsaEd25519(
		signature: EdDSASignature,
		publicKey: Curve25519.Signing.PublicKey
	)
}

public extension SignatureWithPublicKey {
	var signature: Signature {
		switch self {
		case let .eddsaEd25519(signature, _):
			return .eddsaEd25519(signature)
		case let .ecdsaSecp256k1(signature, _):
			return .ecdsaSecp256k1(signature)
		}
	}

	var publicKey: PublicKey {
		switch self {
		case let .eddsaEd25519(_, publicKey):
			return .eddsaEd25519(publicKey)
		case let .ecdsaSecp256k1(_, publicKey):
			return .ecdsaSecp256k1(publicKey)
		}
	}
}
