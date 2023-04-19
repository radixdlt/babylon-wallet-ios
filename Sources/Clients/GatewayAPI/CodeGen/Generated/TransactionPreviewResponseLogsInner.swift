import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.TransactionPreviewResponseLogsInner")
public typealias TransactionPreviewResponseLogsInner = GatewayAPI.TransactionPreviewResponseLogsInner

// MARK: - GatewayAPI.TransactionPreviewResponseLogsInner
extension GatewayAPI {
	public struct TransactionPreviewResponseLogsInner: Codable, Hashable {
		public private(set) var level: String
		public private(set) var message: String

		public init(level: String, message: String) {
			self.level = level
			self.message = message
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case level
			case message
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(level, forKey: .level)
			try container.encode(message, forKey: .message)
		}
	}
}
