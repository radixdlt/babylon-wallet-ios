import Foundation

extension CoreAPI {
	public enum PublicKeyType: String, Codable, CaseIterable {
		case ecdsaSecp256k1 = "EcdsaSecp256k1"
		case eddsaEd25519 = "EddsaEd25519"
	}
}
