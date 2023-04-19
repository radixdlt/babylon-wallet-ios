import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.TransactionSubmitRequest")
public typealias TransactionSubmitRequest = GatewayAPI.TransactionSubmitRequest

// MARK: - GatewayAPI.TransactionSubmitRequest
extension GatewayAPI {
	public struct TransactionSubmitRequest: Codable, Hashable {
		/** Hex-encoded notarized transaction payload which can be submitted. */
		public private(set) var notarizedTransactionHex: String

		public init(notarizedTransactionHex: String) {
			self.notarizedTransactionHex = notarizedTransactionHex
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case notarizedTransactionHex = "notarized_transaction_hex"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(notarizedTransactionHex, forKey: .notarizedTransactionHex)
		}
	}
}
