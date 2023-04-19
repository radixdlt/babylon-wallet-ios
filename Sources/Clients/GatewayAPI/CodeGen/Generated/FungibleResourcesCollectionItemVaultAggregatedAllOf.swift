import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.FungibleResourcesCollectionItemVaultAggregatedAllOf")
public typealias FungibleResourcesCollectionItemVaultAggregatedAllOf = GatewayAPI.FungibleResourcesCollectionItemVaultAggregatedAllOf

// MARK: - GatewayAPI.FungibleResourcesCollectionItemVaultAggregatedAllOf
extension GatewayAPI {
	public struct FungibleResourcesCollectionItemVaultAggregatedAllOf: Codable, Hashable {
		public private(set) var vaults: FungibleResourcesCollectionItemVaultAggregatedVault

		public init(vaults: FungibleResourcesCollectionItemVaultAggregatedVault) {
			self.vaults = vaults
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case vaults
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(vaults, forKey: .vaults)
		}
	}
}
