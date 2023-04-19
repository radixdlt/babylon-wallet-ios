import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.TransactionStatusRequest")
public typealias TransactionStatusRequest = GatewayAPI.TransactionStatusRequest

// MARK: - GatewayAPI.TransactionStatusRequest
extension GatewayAPI {
	public struct TransactionStatusRequest: Codable, Hashable {
		/** Hex-encoded SHA-256 hash. */
		public private(set) var intentHashHex: String

		public init(intentHashHex: String) {
			self.intentHashHex = intentHashHex
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case intentHashHex = "intent_hash_hex"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(intentHashHex, forKey: .intentHashHex)
		}
	}
}
