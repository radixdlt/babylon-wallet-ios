import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.NonFungibleResourcesCollectionItemVaultAggregatedVaultAllOf")
public typealias NonFungibleResourcesCollectionItemVaultAggregatedVaultAllOf = GatewayAPI.NonFungibleResourcesCollectionItemVaultAggregatedVaultAllOf

// MARK: - GatewayAPI.NonFungibleResourcesCollectionItemVaultAggregatedVaultAllOf
extension GatewayAPI {
	public struct NonFungibleResourcesCollectionItemVaultAggregatedVaultAllOf: Codable, Hashable {
		public private(set) var items: [NonFungibleResourcesCollectionItemVaultAggregatedVaultItem]

		public init(items: [NonFungibleResourcesCollectionItemVaultAggregatedVaultItem]) {
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
