import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.NonFungibleResourcesCollectionItemVaultAggregatedVaultItem")
public typealias NonFungibleResourcesCollectionItemVaultAggregatedVaultItem = GatewayAPI.NonFungibleResourcesCollectionItemVaultAggregatedVaultItem

// MARK: - GatewayAPI.NonFungibleResourcesCollectionItemVaultAggregatedVaultItem
extension GatewayAPI {
	public struct NonFungibleResourcesCollectionItemVaultAggregatedVaultItem: Codable, Hashable {
		/** Bech32m-encoded human readable version of the entity's global address or hex-encoded id. */
		public private(set) var vaultAddress: String
		public private(set) var totalCount: Int64
		/** TBD */
		public private(set) var lastUpdatedAtStateVersion: Int64

		public init(vaultAddress: String, totalCount: Int64, lastUpdatedAtStateVersion: Int64) {
			self.vaultAddress = vaultAddress
			self.totalCount = totalCount
			self.lastUpdatedAtStateVersion = lastUpdatedAtStateVersion
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case vaultAddress = "vault_address"
			case totalCount = "total_count"
			case lastUpdatedAtStateVersion = "last_updated_at_state_version"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(vaultAddress, forKey: .vaultAddress)
			try container.encode(totalCount, forKey: .totalCount)
			try container.encode(lastUpdatedAtStateVersion, forKey: .lastUpdatedAtStateVersion)
		}
	}
}
