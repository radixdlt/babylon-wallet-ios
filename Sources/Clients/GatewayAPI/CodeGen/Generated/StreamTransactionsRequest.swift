import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StreamTransactionsRequest")
public typealias StreamTransactionsRequest = GatewayAPI.StreamTransactionsRequest

// MARK: - GatewayAPI.StreamTransactionsRequest
extension GatewayAPI {
	public struct StreamTransactionsRequest: Codable, Hashable {
		public enum KindFilter: String, Codable, CaseIterable {
			case user = "User"
			case epochChange = "EpochChange"
			case all = "All"
		}

		public enum Order: String, Codable, CaseIterable {
			case asc = "Asc"
			case desc = "Desc"
		}

		public private(set) var atLedgerState: LedgerStateSelector?
		/** This cursor allows forward pagination, by providing the cursor from the previous request. */
		public private(set) var cursor: String?
		/** The page size requested. */
		public private(set) var limitPerPage: Int?
		public private(set) var fromLedgerState: LedgerStateSelector?
		/** Limit returned transactions by their kind. Defaults to `user`. */
		public private(set) var kindFilter: KindFilter?
		/** Configures the order of returned result set. Defaults to `desc`. */
		public private(set) var order: Order?

		public init(atLedgerState: LedgerStateSelector? = nil, cursor: String? = nil, limitPerPage: Int? = nil, fromLedgerState: LedgerStateSelector? = nil, kindFilter: KindFilter? = nil, order: Order? = nil) {
			self.atLedgerState = atLedgerState
			self.cursor = cursor
			self.limitPerPage = limitPerPage
			self.fromLedgerState = fromLedgerState
			self.kindFilter = kindFilter
			self.order = order
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case atLedgerState = "at_ledger_state"
			case cursor
			case limitPerPage = "limit_per_page"
			case fromLedgerState = "from_ledger_state"
			case kindFilter = "kind_filter"
			case order
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encodeIfPresent(atLedgerState, forKey: .atLedgerState)
			try container.encodeIfPresent(cursor, forKey: .cursor)
			try container.encodeIfPresent(limitPerPage, forKey: .limitPerPage)
			try container.encodeIfPresent(fromLedgerState, forKey: .fromLedgerState)
			try container.encodeIfPresent(kindFilter, forKey: .kindFilter)
			try container.encodeIfPresent(order, forKey: .order)
		}
	}
}
