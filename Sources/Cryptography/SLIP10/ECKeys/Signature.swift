import CryptoKit
import Foundation
import K1

// MARK: - SLIP10.Signature
public extension SLIP10 {
	enum Signature: Sendable, Hashable {
		case ecdsaSecp256k1(ECDSASignatureRecoverable)
		case eddsaEd25519(EdDSASignature)
	}
}

public extension SLIP10.Signature {
	var rawRepresentation: Data {
		switch self {
		case let .ecdsaSecp256k1(secp256k1):
			return secp256k1.rawRepresentation
		case let .eddsaEd25519(curve25519):
			return curve25519
		}
	}
}
