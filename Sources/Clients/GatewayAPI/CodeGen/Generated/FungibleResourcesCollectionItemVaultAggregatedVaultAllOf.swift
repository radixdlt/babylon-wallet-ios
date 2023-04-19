import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.FungibleResourcesCollectionItemVaultAggregatedVaultAllOf")
public typealias FungibleResourcesCollectionItemVaultAggregatedVaultAllOf = GatewayAPI.FungibleResourcesCollectionItemVaultAggregatedVaultAllOf

// MARK: - GatewayAPI.FungibleResourcesCollectionItemVaultAggregatedVaultAllOf
extension GatewayAPI {
	public struct FungibleResourcesCollectionItemVaultAggregatedVaultAllOf: Codable, Hashable {
		public private(set) var items: [FungibleResourcesCollectionItemVaultAggregatedVaultItem]

		public init(items: [FungibleResourcesCollectionItemVaultAggregatedVaultItem]) {
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
