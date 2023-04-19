import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.FungibleResourcesCollectionItemGloballyAggregated")
public typealias FungibleResourcesCollectionItemGloballyAggregated = GatewayAPI.FungibleResourcesCollectionItemGloballyAggregated

// MARK: - GatewayAPI.FungibleResourcesCollectionItemGloballyAggregated
extension GatewayAPI {
	public struct FungibleResourcesCollectionItemGloballyAggregated: Codable, Hashable {
		public private(set) var aggregationLevel: ResourceAggregationLevel
		/** Bech32m-encoded human readable version of the resource (fungible, non-fungible) global address or hex-encoded id. */
		public private(set) var resourceAddress: String
		/** String-encoded decimal representing the amount of a related fungible resource. */
		public private(set) var amount: String
		/** TBD */
		public private(set) var lastUpdatedAtStateVersion: Int64

		public init(aggregationLevel: ResourceAggregationLevel, resourceAddress: String, amount: String, lastUpdatedAtStateVersion: Int64) {
			self.aggregationLevel = aggregationLevel
			self.resourceAddress = resourceAddress
			self.amount = amount
			self.lastUpdatedAtStateVersion = lastUpdatedAtStateVersion
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case aggregationLevel = "aggregation_level"
			case resourceAddress = "resource_address"
			case amount
			case lastUpdatedAtStateVersion = "last_updated_at_state_version"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(aggregationLevel, forKey: .aggregationLevel)
			try container.encode(resourceAddress, forKey: .resourceAddress)
			try container.encode(amount, forKey: .amount)
			try container.encode(lastUpdatedAtStateVersion, forKey: .lastUpdatedAtStateVersion)
		}
	}
}
