import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.NonFungibleIdsCollectionAllOf")
public typealias NonFungibleIdsCollectionAllOf = GatewayAPI.NonFungibleIdsCollectionAllOf

// MARK: - GatewayAPI.NonFungibleIdsCollectionAllOf
extension GatewayAPI {
	public struct NonFungibleIdsCollectionAllOf: Codable, Hashable {
		public private(set) var items: [NonFungibleIdsCollectionItem]

		public init(items: [NonFungibleIdsCollectionItem]) {
			self.items = items
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case items
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(items, forKey: .items)
		}
	}
}
