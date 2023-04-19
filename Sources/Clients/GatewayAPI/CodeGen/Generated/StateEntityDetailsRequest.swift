import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateEntityDetailsRequest")
public typealias StateEntityDetailsRequest = GatewayAPI.StateEntityDetailsRequest

// MARK: - GatewayAPI.StateEntityDetailsRequest
extension GatewayAPI {
	public struct StateEntityDetailsRequest: Codable, Hashable {
		public private(set) var atLedgerState: LedgerStateSelector?
		public private(set) var addresses: [String]
		public private(set) var aggregationLevel: ResourceAggregationLevel?

		public init(atLedgerState: LedgerStateSelector? = nil, addresses: [String], aggregationLevel: ResourceAggregationLevel? = nil) {
			self.atLedgerState = atLedgerState
			self.addresses = addresses
			self.aggregationLevel = aggregationLevel
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case atLedgerState = "at_ledger_state"
			case addresses
			case aggregationLevel = "aggregation_level"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encodeIfPresent(atLedgerState, forKey: .atLedgerState)
			try container.encode(addresses, forKey: .addresses)
			try container.encodeIfPresent(aggregationLevel, forKey: .aggregationLevel)
		}
	}
}
