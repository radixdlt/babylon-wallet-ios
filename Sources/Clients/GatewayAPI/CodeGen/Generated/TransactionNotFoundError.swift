import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.TransactionNotFoundError")
public typealias TransactionNotFoundError = GatewayAPI.TransactionNotFoundError

// MARK: - GatewayAPI.TransactionNotFoundError
extension GatewayAPI {
	public struct TransactionNotFoundError: Codable, Hashable {
		/** The type of error. Each subtype may have its own additional structured fields. */
		public private(set) var type: String
		/** Hex-encoded SHA-256 hash. */
		public private(set) var intentHashHex: String

		public init(type: String, intentHashHex: String) {
			self.type = type
			self.intentHashHex = intentHashHex
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case type
			case intentHashHex = "intent_hash_hex"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(type, forKey: .type)
			try container.encode(intentHashHex, forKey: .intentHashHex)
		}
	}
}
