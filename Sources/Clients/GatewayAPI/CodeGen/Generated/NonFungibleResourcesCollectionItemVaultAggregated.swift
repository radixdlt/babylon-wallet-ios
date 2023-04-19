import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.NonFungibleResourcesCollectionItemVaultAggregated")
public typealias NonFungibleResourcesCollectionItemVaultAggregated = GatewayAPI.NonFungibleResourcesCollectionItemVaultAggregated

// MARK: - GatewayAPI.NonFungibleResourcesCollectionItemVaultAggregated
extension GatewayAPI {
	public struct NonFungibleResourcesCollectionItemVaultAggregated: Codable, Hashable {
		public private(set) var aggregationLevel: ResourceAggregationLevel
		/** Bech32m-encoded human readable version of the resource (fungible, non-fungible) global address or hex-encoded id. */
		public private(set) var resourceAddress: String
		public private(set) var vaults: NonFungibleResourcesCollectionItemVaultAggregatedVault

		public init(aggregationLevel: ResourceAggregationLevel, resourceAddress: String, vaults: NonFungibleResourcesCollectionItemVaultAggregatedVault) {
			self.aggregationLevel = aggregationLevel
			self.resourceAddress = resourceAddress
			self.vaults = vaults
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case aggregationLevel = "aggregation_level"
			case resourceAddress = "resource_address"
			case vaults
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(aggregationLevel, forKey: .aggregationLevel)
			try container.encode(resourceAddress, forKey: .resourceAddress)
			try container.encode(vaults, forKey: .vaults)
		}
	}
}
