import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.LedgerStateMixin")
public typealias LedgerStateMixin = GatewayAPI.LedgerStateMixin

// MARK: - GatewayAPI.LedgerStateMixin
extension GatewayAPI {
	public struct LedgerStateMixin: Codable, Hashable {
		public private(set) var ledgerState: LedgerState

		public init(ledgerState: LedgerState) {
			self.ledgerState = ledgerState
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case ledgerState = "ledger_state"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(ledgerState, forKey: .ledgerState)
		}
	}
}
