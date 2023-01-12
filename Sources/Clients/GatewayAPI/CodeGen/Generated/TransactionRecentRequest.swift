//
// TransactionRecentRequest.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import ClientPrelude
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.TransactionRecentRequest")
public typealias TransactionRecentRequest = GatewayAPI.TransactionRecentRequest

// MARK: - GatewayAPI.TransactionRecentRequest
public extension GatewayAPI {
	struct TransactionRecentRequest: Codable, Hashable {
		public private(set) var atLedgerState: LedgerStateSelector?
		public private(set) var fromLedgerState: LedgerStateSelector?
		/** This cursor allows forward pagination, by providing the cursor from the previous request. */
		public private(set) var cursor: String?
		/** The page size requested. */
		public private(set) var limit: Int?

		public init(atLedgerState: LedgerStateSelector? = nil, fromLedgerState: LedgerStateSelector? = nil, cursor: String? = nil, limit: Int? = nil) {
			self.atLedgerState = atLedgerState
			self.fromLedgerState = fromLedgerState
			self.cursor = cursor
			self.limit = limit
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case atLedgerState = "at_ledger_state"
			case fromLedgerState = "from_ledger_state"
			case cursor
			case limit
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encodeIfPresent(atLedgerState, forKey: .atLedgerState)
			try container.encodeIfPresent(fromLedgerState, forKey: .fromLedgerState)
			try container.encodeIfPresent(cursor, forKey: .cursor)
			try container.encodeIfPresent(limit, forKey: .limit)
		}
	}
}
