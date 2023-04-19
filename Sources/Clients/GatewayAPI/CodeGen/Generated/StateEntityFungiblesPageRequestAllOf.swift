import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateEntityFungiblesPageRequestAllOf")
public typealias StateEntityFungiblesPageRequestAllOf = GatewayAPI.StateEntityFungiblesPageRequestAllOf

// MARK: - GatewayAPI.StateEntityFungiblesPageRequestAllOf
extension GatewayAPI {
	public struct StateEntityFungiblesPageRequestAllOf: Codable, Hashable {
		/** Bech32m-encoded human readable version of the entity's global address or hex-encoded id. */
		public private(set) var address: String
		public private(set) var aggregationLevel: ResourceAggregationLevel?

		public init(address: String, aggregationLevel: ResourceAggregationLevel? = nil) {
			self.address = address
			self.aggregationLevel = aggregationLevel
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case address
			case aggregationLevel = "aggregation_level"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(address, forKey: .address)
			try container.encodeIfPresent(aggregationLevel, forKey: .aggregationLevel)
		}
	}
}
