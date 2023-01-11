import CryptoKit
import Foundation
import K1

// MARK: - PublicKey
public enum PublicKey: Sendable, Hashable {
	case ecdsaSecp256k1(K1.PublicKey)
	case eddsaEd25519(Curve25519.Signing.PublicKey)
}

public extension PublicKey {
	/// Expects a non hashed `message`, will SHA256 double hash it for secp256k1,
	/// but not for Curve25519.
	func isValidSignature(
		_ signatureWrapper: Signature,
		for message: any DataProtocol
	) -> Bool {
		switch (signatureWrapper, self) {
		case let (.ecdsaSecp256k1(ecdsaSecp256k1Signature), .ecdsaSecp256k1(ecdsaSecp256k1PublicKey)):
			// We do Radix double SHA256 hashing, needed for secp256k1 but not for Curve25519
			let hashed = Data(SHA256.hash(data: Data(SHA256.hash(data: message))))
			return (try? ecdsaSecp256k1Signature.wasSigned(by: ecdsaSecp256k1PublicKey, hashedMessage: hashed, mode: .default)) ?? false

		case (.ecdsaSecp256k1, .eddsaEd25519):
			return false

		case (.eddsaEd25519, .ecdsaSecp256k1):
			return false

		case let (.eddsaEd25519(eddsaEd25519Signature), .eddsaEd25519(eddsaEd25519PublicKey)):
			return eddsaEd25519PublicKey.isValidSignature(eddsaEd25519Signature, for: message)
		}
	}
}

public extension SLIP10.PublicKey {
	/// For ECDSA secp256k1 public keys this will use the compressed representation
	/// For EdDSA Curve25519 there is no difference between compressed and uncompressed.
	var compressedRepresentation: Data {
		switch self {
		case let .eddsaEd25519(publicKey):
			return publicKey.compressedRepresentation
		case let .ecdsaSecp256k1(publicKey):
			return publicKey.compressedRepresentation
		}
	}

	/// For ECDSA secp256k1 public keys this will use the uncompressed representation
	/// For EdDSA Curve25519 there is no difference between compressed and uncompressed.
	var uncompressedRepresentation: Data {
		switch self {
		case let .eddsaEd25519(publicKey):
			return publicKey.rawRepresentation
		case let .ecdsaSecp256k1(publicKey):
			return try! Data(publicKey.rawRepresentation(format: .uncompressed))
		}
	}
}
