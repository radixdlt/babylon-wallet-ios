import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.InvalidTransactionError")
public typealias InvalidTransactionError = GatewayAPI.InvalidTransactionError

// MARK: - GatewayAPI.InvalidTransactionError
extension GatewayAPI {
	public struct InvalidTransactionError: Codable, Hashable {
		/** The type of error. Each subtype may have its own additional structured fields. */
		public private(set) var type: String

		public init(type: String) {
			self.type = type
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case type
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(type, forKey: .type)
		}
	}
}
