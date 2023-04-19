import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.TransactionStatusResponseKnownPayloadItem")
public typealias TransactionStatusResponseKnownPayloadItem = GatewayAPI.TransactionStatusResponseKnownPayloadItem

// MARK: - GatewayAPI.TransactionStatusResponseKnownPayloadItem
extension GatewayAPI {
	public struct TransactionStatusResponseKnownPayloadItem: Codable, Hashable {
		/** Hex-encoded SHA-256 hash. */
		public private(set) var payloadHashHex: String
		public private(set) var status: TransactionStatus
		public private(set) var errorMessage: String?

		public init(payloadHashHex: String, status: TransactionStatus, errorMessage: String? = nil) {
			self.payloadHashHex = payloadHashHex
			self.status = status
			self.errorMessage = errorMessage
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case payloadHashHex = "payload_hash_hex"
			case status
			case errorMessage = "error_message"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(payloadHashHex, forKey: .payloadHashHex)
			try container.encode(status, forKey: .status)
			try container.encodeIfPresent(errorMessage, forKey: .errorMessage)
		}
	}
}
