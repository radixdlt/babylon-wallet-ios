import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.CursorLimitMixin")
public typealias CursorLimitMixin = GatewayAPI.CursorLimitMixin

// MARK: - GatewayAPI.CursorLimitMixin
extension GatewayAPI {
	public struct CursorLimitMixin: Codable, Hashable {
		/** This cursor allows forward pagination, by providing the cursor from the previous request. */
		public private(set) var cursor: String?
		/** The page size requested. */
		public private(set) var limitPerPage: Int?

		public init(cursor: String? = nil, limitPerPage: Int? = nil) {
			self.cursor = cursor
			self.limitPerPage = limitPerPage
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case cursor
			case limitPerPage = "limit_per_page"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encodeIfPresent(cursor, forKey: .cursor)
			try container.encodeIfPresent(limitPerPage, forKey: .limitPerPage)
		}
	}
}
