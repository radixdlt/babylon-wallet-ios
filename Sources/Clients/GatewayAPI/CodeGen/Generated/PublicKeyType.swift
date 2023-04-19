import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.PublicKeyType")
public typealias PublicKeyType = GatewayAPI.PublicKeyType

// MARK: - GatewayAPI.PublicKeyType
extension GatewayAPI {
	public enum PublicKeyType: String, Codable, CaseIterable {
		case ecdsaSecp256k1 = "EcdsaSecp256k1"
		case eddsaEd25519 = "EddsaEd25519"
	}
}
