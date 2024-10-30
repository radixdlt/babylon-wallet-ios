
@available(*, deprecated, renamed: "GatewayAPI.FungibleResourcesCollectionItem")
typealias FungibleResourcesCollectionItem = GatewayAPI.FungibleResourcesCollectionItem

// MARK: - GatewayAPI.FungibleResourcesCollectionItem
extension GatewayAPI {
	enum FungibleResourcesCollectionItem: Codable, Hashable {
		case globallyAggregated(FungibleResourcesCollectionItemGloballyAggregated)
		case vaultAggregated(FungibleResourcesCollectionItemVaultAggregated)

		private enum CodingKeys: String, CodingKey {
			case aggregationLevel = "aggregation_level"
		}

		var global: FungibleResourcesCollectionItemGloballyAggregated? {
			if case let .globallyAggregated(wrapped) = self {
				return wrapped
			}
			return nil
		}

		var vault: FungibleResourcesCollectionItemVaultAggregated? {
			if case let .vaultAggregated(wrapped) = self {
				return wrapped
			}
			return nil
		}

		var resourceAddress: String {
			switch self {
			case let .globallyAggregated(wrapped):
				wrapped.resourceAddress
			case let .vaultAggregated(wrapped):
				wrapped.resourceAddress
			}
		}

		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			let aggregationLevel = try container.decode(ResourceAggregationLevel.self, forKey: .aggregationLevel)

			switch aggregationLevel {
			case .global:
				self = try .globallyAggregated(FungibleResourcesCollectionItemGloballyAggregated(from: decoder))
			case .vault:
				self = try .vaultAggregated(FungibleResourcesCollectionItemVaultAggregated(from: decoder))
			}
		}

		func encode(to encoder: Encoder) throws {
			switch self {
			case let .globallyAggregated(item):
				try item.encode(to: encoder)
			case let .vaultAggregated(item):
				try item.encode(to: encoder)
			}
		}
	}
}
