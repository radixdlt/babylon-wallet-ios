import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.NonFungibleResourcesCollectionAllOf")
public typealias NonFungibleResourcesCollectionAllOf = GatewayAPI.NonFungibleResourcesCollectionAllOf

// MARK: - GatewayAPI.NonFungibleResourcesCollectionAllOf
extension GatewayAPI {
	public struct NonFungibleResourcesCollectionAllOf: Codable, Hashable {
		public private(set) var items: [NonFungibleResourcesCollectionItem]

		public init(items: [NonFungibleResourcesCollectionItem]) {
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
