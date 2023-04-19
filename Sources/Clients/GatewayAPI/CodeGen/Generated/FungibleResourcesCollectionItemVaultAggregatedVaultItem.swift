import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.FungibleResourcesCollectionItemVaultAggregatedVaultItem")
public typealias FungibleResourcesCollectionItemVaultAggregatedVaultItem = GatewayAPI.FungibleResourcesCollectionItemVaultAggregatedVaultItem

// MARK: - GatewayAPI.FungibleResourcesCollectionItemVaultAggregatedVaultItem
extension GatewayAPI {
	public struct FungibleResourcesCollectionItemVaultAggregatedVaultItem: Codable, Hashable {
		/** Bech32m-encoded human readable version of the entity's global address or hex-encoded id. */
		public private(set) var vaultAddress: String
		/** String-encoded decimal representing the amount of a related fungible resource. */
		public private(set) var amount: String
		/** TBD */
		public private(set) var lastUpdatedAtStateVersion: Int64

		public init(vaultAddress: String, amount: String, lastUpdatedAtStateVersion: Int64) {
			self.vaultAddress = vaultAddress
			self.amount = amount
			self.lastUpdatedAtStateVersion = lastUpdatedAtStateVersion
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case vaultAddress = "vault_address"
			case amount
			case lastUpdatedAtStateVersion = "last_updated_at_state_version"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(vaultAddress, forKey: .vaultAddress)
			try container.encode(amount, forKey: .amount)
			try container.encode(lastUpdatedAtStateVersion, forKey: .lastUpdatedAtStateVersion)
		}
	}
}
