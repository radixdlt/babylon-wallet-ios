import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.FungibleResourcesCollectionAllOf")
public typealias FungibleResourcesCollectionAllOf = GatewayAPI.FungibleResourcesCollectionAllOf

// MARK: - GatewayAPI.FungibleResourcesCollectionAllOf
extension GatewayAPI {
	public struct FungibleResourcesCollectionAllOf: Codable, Hashable {
		public private(set) var items: [FungibleResourcesCollectionItem]

		public init(items: [FungibleResourcesCollectionItem]) {
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
