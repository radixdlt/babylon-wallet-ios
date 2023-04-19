import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateValidatorsListRequest")
public typealias StateValidatorsListRequest = GatewayAPI.StateValidatorsListRequest

// MARK: - GatewayAPI.StateValidatorsListRequest
extension GatewayAPI {
	public struct StateValidatorsListRequest: Codable, Hashable {
		public private(set) var atLedgerState: LedgerStateSelector?
		/** This cursor allows forward pagination, by providing the cursor from the previous request. */
		public private(set) var cursor: String?

		public init(atLedgerState: LedgerStateSelector? = nil, cursor: String? = nil) {
			self.atLedgerState = atLedgerState
			self.cursor = cursor
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case atLedgerState = "at_ledger_state"
			case cursor
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encodeIfPresent(atLedgerState, forKey: .atLedgerState)
			try container.encodeIfPresent(cursor, forKey: .cursor)
		}
	}
}
