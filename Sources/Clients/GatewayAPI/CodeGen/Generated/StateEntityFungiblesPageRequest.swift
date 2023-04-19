import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateEntityFungiblesPageRequest")
public typealias StateEntityFungiblesPageRequest = GatewayAPI.StateEntityFungiblesPageRequest

// MARK: - GatewayAPI.StateEntityFungiblesPageRequest
extension GatewayAPI {
	public struct StateEntityFungiblesPageRequest: Codable, Hashable {
		public private(set) var atLedgerState: LedgerStateSelector?
		/** This cursor allows forward pagination, by providing the cursor from the previous request. */
		public private(set) var cursor: String?
		/** The page size requested. */
		public private(set) var limitPerPage: Int?
		/** Bech32m-encoded human readable version of the entity's global address or hex-encoded id. */
		public private(set) var address: String
		public private(set) var aggregationLevel: ResourceAggregationLevel?

		public init(atLedgerState: LedgerStateSelector? = nil, cursor: String? = nil, limitPerPage: Int? = nil, address: String, aggregationLevel: ResourceAggregationLevel? = nil) {
			self.atLedgerState = atLedgerState
			self.cursor = cursor
			self.limitPerPage = limitPerPage
			self.address = address
			self.aggregationLevel = aggregationLevel
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case atLedgerState = "at_ledger_state"
			case cursor
			case limitPerPage = "limit_per_page"
			case address
			case aggregationLevel = "aggregation_level"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encodeIfPresent(atLedgerState, forKey: .atLedgerState)
			try container.encodeIfPresent(cursor, forKey: .cursor)
			try container.encodeIfPresent(limitPerPage, forKey: .limitPerPage)
			try container.encode(address, forKey: .address)
			try container.encodeIfPresent(aggregationLevel, forKey: .aggregationLevel)
		}
	}
}
