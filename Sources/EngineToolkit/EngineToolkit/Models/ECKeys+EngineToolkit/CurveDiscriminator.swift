import Foundation

internal enum CurveDiscriminator: String, Codable {
	case ecdsaSecp256k1 = "EcdsaSecp256k1"
	case eddsaEd25519 = "EddsaEd25519"
}
