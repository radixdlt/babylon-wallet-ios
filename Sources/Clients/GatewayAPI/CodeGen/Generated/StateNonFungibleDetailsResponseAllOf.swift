import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateNonFungibleDetailsResponseAllOf")
public typealias StateNonFungibleDetailsResponseAllOf = GatewayAPI.StateNonFungibleDetailsResponseAllOf

// MARK: - GatewayAPI.StateNonFungibleDetailsResponseAllOf
extension GatewayAPI {
	public struct StateNonFungibleDetailsResponseAllOf: Codable, Hashable {
		/** Bech32m-encoded human readable version of the resource (fungible, non-fungible) global address or hex-encoded id. */
		public private(set) var resourceAddress: String
		public private(set) var nonFungibleIdType: NonFungibleIdType
		public private(set) var nonFungibleIds: [StateNonFungibleDetailsResponseItem]

		public init(resourceAddress: String, nonFungibleIdType: NonFungibleIdType, nonFungibleIds: [StateNonFungibleDetailsResponseItem]) {
			self.resourceAddress = resourceAddress
			self.nonFungibleIdType = nonFungibleIdType
			self.nonFungibleIds = nonFungibleIds
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case resourceAddress = "resource_address"
			case nonFungibleIdType = "non_fungible_id_type"
			case nonFungibleIds = "non_fungible_ids"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(resourceAddress, forKey: .resourceAddress)
			try container.encode(nonFungibleIdType, forKey: .nonFungibleIdType)
			try container.encode(nonFungibleIds, forKey: .nonFungibleIds)
		}
	}
}
