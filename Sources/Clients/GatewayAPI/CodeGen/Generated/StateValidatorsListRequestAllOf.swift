import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateValidatorsListRequestAllOf")
public typealias StateValidatorsListRequestAllOf = GatewayAPI.StateValidatorsListRequestAllOf

// MARK: - GatewayAPI.StateValidatorsListRequestAllOf
extension GatewayAPI {
	public struct StateValidatorsListRequestAllOf: Codable, Hashable {
		/** This cursor allows forward pagination, by providing the cursor from the previous request. */
		public private(set) var cursor: String?

		public init(cursor: String? = nil) {
			self.cursor = cursor
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case cursor
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encodeIfPresent(cursor, forKey: .cursor)
		}
	}
}
