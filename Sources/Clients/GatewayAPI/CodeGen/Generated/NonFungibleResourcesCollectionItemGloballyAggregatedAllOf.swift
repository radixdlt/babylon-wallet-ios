import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.NonFungibleResourcesCollectionItemGloballyAggregatedAllOf")
public typealias NonFungibleResourcesCollectionItemGloballyAggregatedAllOf = GatewayAPI.NonFungibleResourcesCollectionItemGloballyAggregatedAllOf

// MARK: - GatewayAPI.NonFungibleResourcesCollectionItemGloballyAggregatedAllOf
extension GatewayAPI {
	public struct NonFungibleResourcesCollectionItemGloballyAggregatedAllOf: Codable, Hashable {
		/** TBA */
		public private(set) var amount: Int64
		/** TBD */
		public private(set) var lastUpdatedAtStateVersion: Int64

		public init(amount: Int64, lastUpdatedAtStateVersion: Int64) {
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
