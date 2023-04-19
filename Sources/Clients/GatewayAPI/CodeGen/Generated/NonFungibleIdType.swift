import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.NonFungibleIdType")
public typealias NonFungibleIdType = GatewayAPI.NonFungibleIdType

// MARK: - GatewayAPI.NonFungibleIdType
extension GatewayAPI {
	public enum NonFungibleIdType: String, Codable, CaseIterable {
		case string = "String"
		case integer = "Integer"
		case bytes = "Bytes"
		case uuid = "Uuid"
	}
}
