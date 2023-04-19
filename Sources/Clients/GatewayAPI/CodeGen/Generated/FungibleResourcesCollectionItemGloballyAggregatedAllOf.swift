import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.FungibleResourcesCollectionItemGloballyAggregatedAllOf")
public typealias FungibleResourcesCollectionItemGloballyAggregatedAllOf = GatewayAPI.FungibleResourcesCollectionItemGloballyAggregatedAllOf

// MARK: - GatewayAPI.FungibleResourcesCollectionItemGloballyAggregatedAllOf
extension GatewayAPI {
	public struct FungibleResourcesCollectionItemGloballyAggregatedAllOf: Codable, Hashable {
		/** String-encoded decimal representing the amount of a related fungible resource. */
		public private(set) var amount: String
		/** TBD */
		public private(set) var lastUpdatedAtStateVersion: Int64

		public init(amount: String, lastUpdatedAtStateVersion: Int64) {
			self.amount = amount
			self.lastUpdatedAtStateVersion = lastUpdatedAtStateVersion
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case amount
			case lastUpdatedAtStateVersion = "last_updated_at_state_version"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(amount, forKey: .amount)
			try container.encode(lastUpdatedAtStateVersion, forKey: .lastUpdatedAtStateVersion)
		}
	}
}
