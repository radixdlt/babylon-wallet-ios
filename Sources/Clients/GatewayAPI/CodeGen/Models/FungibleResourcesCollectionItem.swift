import Foundation

@available(*, deprecated, renamed: "GatewayAPI.FungibleResourcesCollectionItem")
public typealias FungibleResourcesCollectionItem = GatewayAPI.FungibleResourcesCollectionItem

// MARK: - GatewayAPI.FungibleResourcesCollectionItem
extension GatewayAPI {
	public enum FungibleResourcesCollectionItem: Codable, Hashable {
		case globallyAggregated(FungibleResourcesCollectionItemGloballyAggregated)
		case vaultAggregated(FungibleResourcesCollectionItemVaultAggregated)

		private enum CodingKeys: String, CodingKey {
			case aggregationLevel = "aggregation_level"
		}

		public init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			let aggregationLevel = try container.decode(ResourceAggregationLevel.self, forKey: .aggregationLevel)

			switch aggregationLevel {
			case .global:
				self = .globallyAggregated(try FungibleResourcesCollectionItemGloballyAggregated(from: decoder))
			case .vault:
				self = .vaultAggregated(try FungibleResourcesCollectionItemVaultAggregated(from: decoder))
			}
		}

		public func encode(to encoder: Encoder) throws {
			switch self {
			case let .globallyAggregated(item):
				try item.encode(to: encoder)
			case let .vaultAggregated(item):
				try item.encode(to: encoder)
			}
		}
	}
}
