import Foundation

// MARK: - CurveDiscriminator
public enum CurveDiscriminator: String, Sendable, Hashable, Codable {
	case ecdsaSecp256k1 = "EcdsaSecp256k1"
	case eddsaEd25519 = "EddsaEd25519"
}

// MARK: - ECPrimitiveKind
public enum ECPrimitiveKind: String, Sendable, Codable, Hashable {
	case publicKey = "PublicKey"
	case signature = "Signature"
}
