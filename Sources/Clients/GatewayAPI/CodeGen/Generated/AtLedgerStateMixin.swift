import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.AtLedgerStateMixin")
public typealias AtLedgerStateMixin = GatewayAPI.AtLedgerStateMixin

// MARK: - GatewayAPI.AtLedgerStateMixin
extension GatewayAPI {
	public struct AtLedgerStateMixin: Codable, Hashable {
		public private(set) var atLedgerState: LedgerStateSelector?

		public init(atLedgerState: LedgerStateSelector? = nil) {
			self.atLedgerState = atLedgerState
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case atLedgerState = "at_ledger_state"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encodeIfPresent(atLedgerState, forKey: .atLedgerState)
		}
	}
}
