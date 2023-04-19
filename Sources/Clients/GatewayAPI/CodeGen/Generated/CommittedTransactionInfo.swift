import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.CommittedTransactionInfo")
public typealias CommittedTransactionInfo = GatewayAPI.CommittedTransactionInfo

// MARK: - GatewayAPI.CommittedTransactionInfo
extension GatewayAPI {
	public struct CommittedTransactionInfo: Codable, Hashable {
		public private(set) var stateVersion: Int64?
		public private(set) var transactionStatus: TransactionStatus
		/** Hex-encoded SHA-256 hash. */
		public private(set) var payloadHashHex: String?
		/** Hex-encoded SHA-256 hash. */
		public private(set) var intentHashHex: String?
		public private(set) var feePaid: TokenAmount?
		public private(set) var confirmedAt: Date?
		public private(set) var errorMessage: String?

		public init(stateVersion: Int64?, transactionStatus: TransactionStatus, payloadHashHex: String? = nil, intentHashHex: String? = nil, feePaid: TokenAmount? = nil, confirmedAt: Date? = nil, errorMessage: String? = nil) {
			self.stateVersion = stateVersion
			self.transactionStatus = transactionStatus
			self.payloadHashHex = payloadHashHex
			self.intentHashHex = intentHashHex
			self.feePaid = feePaid
			self.confirmedAt = confirmedAt
			self.errorMessage = errorMessage
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case stateVersion = "state_version"
			case transactionStatus = "transaction_status"
			case payloadHashHex = "payload_hash_hex"
			case intentHashHex = "intent_hash_hex"
			case feePaid = "fee_paid"
			case confirmedAt = "confirmed_at"
			case errorMessage = "error_message"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(stateVersion, forKey: .stateVersion)
			try container.encode(transactionStatus, forKey: .transactionStatus)
			try container.encodeIfPresent(payloadHashHex, forKey: .payloadHashHex)
			try container.encodeIfPresent(intentHashHex, forKey: .intentHashHex)
			try container.encodeIfPresent(feePaid, forKey: .feePaid)
			try container.encodeIfPresent(confirmedAt, forKey: .confirmedAt)
			try container.encodeIfPresent(errorMessage, forKey: .errorMessage)
		}
	}
}
