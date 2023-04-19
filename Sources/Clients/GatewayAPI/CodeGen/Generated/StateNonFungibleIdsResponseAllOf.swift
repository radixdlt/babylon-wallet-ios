import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateNonFungibleIdsResponseAllOf")
public typealias StateNonFungibleIdsResponseAllOf = GatewayAPI.StateNonFungibleIdsResponseAllOf

// MARK: - GatewayAPI.StateNonFungibleIdsResponseAllOf
extension GatewayAPI {
	public struct StateNonFungibleIdsResponseAllOf: Codable, Hashable {
		/** Bech32m-encoded human readable version of the resource (fungible, non-fungible) global address or hex-encoded id. */
		public private(set) var resourceAddress: String
		public private(set) var nonFungibleIds: NonFungibleIdsCollection

		public init(resourceAddress: String, nonFungibleIds: NonFungibleIdsCollection) {
			self.resourceAddress = resourceAddress
			self.nonFungibleIds = nonFungibleIds
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case resourceAddress = "resource_address"
			case nonFungibleIds = "non_fungible_ids"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(resourceAddress, forKey: .resourceAddress)
			try container.encode(nonFungibleIds, forKey: .nonFungibleIds)
		}
	}
}
