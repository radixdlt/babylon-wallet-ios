import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.TransactionCommittedDetailsRequest")
public typealias TransactionCommittedDetailsRequest = GatewayAPI.TransactionCommittedDetailsRequest

// MARK: - GatewayAPI.TransactionCommittedDetailsRequest
extension GatewayAPI {
	public struct TransactionCommittedDetailsRequest: Codable, Hashable {
		public private(set) var atLedgerState: LedgerStateSelector?
		/** Hex-encoded SHA-256 hash. */
		public private(set) var intentHashHex: String

		public init(atLedgerState: LedgerStateSelector? = nil, intentHashHex: String) {
			self.atLedgerState = atLedgerState
			self.intentHashHex = intentHashHex
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case atLedgerState = "at_ledger_state"
			case intentHashHex = "intent_hash_hex"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encodeIfPresent(atLedgerState, forKey: .atLedgerState)
			try container.encode(intentHashHex, forKey: .intentHashHex)
		}
	}
}
