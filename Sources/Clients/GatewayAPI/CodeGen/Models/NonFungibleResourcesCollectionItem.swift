import Foundation

@available(*, deprecated, renamed: "GatewayAPI.FungibleResourcesCollectionItem")
public typealias NonFungibleResourcesCollectionItem = GatewayAPI.FungibleResourcesCollectionItem

// MARK: - GatewayAPI.NonFungibleResourcesCollectionItem
extension GatewayAPI {
	public enum NonFungibleResourcesCollectionItem: Codable, Hashable {
		case globallyAggregated(NonFungibleResourcesCollectionItemGloballyAggregated)
		case vaultAggregated(NonFungibleResourcesCollectionItemVaultAggregated)

		private enum CodingKeys: String, CodingKey {
			case aggregationLevel = "aggregation_level"
		}

		public var global: NonFungibleResourcesCollectionItemGloballyAggregated? {
			if case let .globallyAggregated(wrapped) = self {
				return wrapped
			}
			return nil
		}

		public var vault: NonFungibleResourcesCollectionItemVaultAggregated? {
			if case let .vaultAggregated(wrapped) = self {
				return wrapped
			}
			return nil
		}

		public var resourceAddress: String {
			switch self {
			case let .globallyAggregated(wrapped):
				return wrapped.resourceAddress
			case let .vaultAggregated(wrapped):
				return wrapped.resourceAddress
			}
		}

		public init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			let aggregationLevel = try container.decode(ResourceAggregationLevel.self, forKey: .aggregationLevel)

			switch aggregationLevel {
			case .global:
				self = try .globallyAggregated(NonFungibleResourcesCollectionItemGloballyAggregated(from: decoder))
			case .vault:
                                self = try .vaultAggregated(NonFungibleResourcesCollectionItemVaultAggregated(from: decoder))
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
