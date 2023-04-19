import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.ValidatorCollection")
public typealias ValidatorCollection = GatewayAPI.ValidatorCollection

// MARK: - GatewayAPI.ValidatorCollection
extension GatewayAPI {
	public struct ValidatorCollection: Codable, Hashable {
		/** Total number of items in underlying collection, fragment of which is available in `items` collection. */
		public private(set) var totalCount: Int64?
		/** If specified, contains a cursor to query previous page of the `items` collection. */
		public private(set) var previousCursor: String?
		/** If specified, contains a cursor to query next page of the `items` collection. */
		public private(set) var nextCursor: String?
		public private(set) var items: [ValidatorCollectionItem]

		public init(totalCount: Int64? = nil, previousCursor: String? = nil, nextCursor: String? = nil, items: [ValidatorCollectionItem]) {
			self.totalCount = totalCount
			self.previousCursor = previousCursor
			self.nextCursor = nextCursor
			self.items = items
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case totalCount = "total_count"
			case previousCursor = "previous_cursor"
			case nextCursor = "next_cursor"
			case items
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encodeIfPresent(totalCount, forKey: .totalCount)
			try container.encodeIfPresent(previousCursor, forKey: .previousCursor)
			try container.encodeIfPresent(nextCursor, forKey: .nextCursor)
			try container.encode(items, forKey: .items)
		}
	}
}
