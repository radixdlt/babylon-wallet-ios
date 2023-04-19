import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.NonFungibleResourcesCollectionItemVaultAggregatedAllOf")
public typealias NonFungibleResourcesCollectionItemVaultAggregatedAllOf = GatewayAPI.NonFungibleResourcesCollectionItemVaultAggregatedAllOf

// MARK: - GatewayAPI.NonFungibleResourcesCollectionItemVaultAggregatedAllOf
extension GatewayAPI {
	public struct NonFungibleResourcesCollectionItemVaultAggregatedAllOf: Codable, Hashable {
		public private(set) var vaults: NonFungibleResourcesCollectionItemVaultAggregatedVault

		public init(vaults: NonFungibleResourcesCollectionItemVaultAggregatedVault) {
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
