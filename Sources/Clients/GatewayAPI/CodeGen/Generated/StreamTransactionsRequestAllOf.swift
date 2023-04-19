import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StreamTransactionsRequestAllOf")
public typealias StreamTransactionsRequestAllOf = GatewayAPI.StreamTransactionsRequestAllOf

// MARK: - GatewayAPI.StreamTransactionsRequestAllOf
extension GatewayAPI {
	public struct StreamTransactionsRequestAllOf: Codable, Hashable {
		public enum KindFilter: String, Codable, CaseIterable {
			case user = "User"
			case epochChange = "EpochChange"
			case all = "All"
		}

		public enum Order: String, Codable, CaseIterable {
			case asc = "Asc"
			case desc = "Desc"
		}

		public private(set) var fromLedgerState: LedgerStateSelector?
		/** Limit returned transactions by their kind. Defaults to `user`. */
		public private(set) var kindFilter: KindFilter?
		/** Configures the order of returned result set. Defaults to `desc`. */
		public private(set) var order: Order?

		public init(fromLedgerState: LedgerStateSelector? = nil, kindFilter: KindFilter? = nil, order: Order? = nil) {
			self.fromLedgerState = fromLedgerState
			self.kindFilter = kindFilter
			self.order = order
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case fromLedgerState = "from_ledger_state"
			case kindFilter = "kind_filter"
			case order
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encodeIfPresent(fromLedgerState, forKey: .fromLedgerState)
			try container.encodeIfPresent(kindFilter, forKey: .kindFilter)
			try container.encodeIfPresent(order, forKey: .order)
		}
	}
}
