import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateEntityDetailsResponseItem")
public typealias StateEntityDetailsResponseItem = GatewayAPI.StateEntityDetailsResponseItem

// MARK: - GatewayAPI.StateEntityDetailsResponseItem
extension GatewayAPI {
	public struct StateEntityDetailsResponseItem: Codable, Hashable {
		/** Bech32m-encoded human readable version of the entity's global address or hex-encoded id. */
		public private(set) var address: String
		public private(set) var fungibleResources: FungibleResourcesCollection?
		public private(set) var nonFungibleResources: NonFungibleResourcesCollection?
		public private(set) var ancestorIdentities: StateEntityDetailsResponseItemAncestorIdentities?
		public private(set) var metadata: EntityMetadataCollection
		public private(set) var details: StateEntityDetailsResponseItemDetails?

		public init(address: String, fungibleResources: FungibleResourcesCollection? = nil, nonFungibleResources: NonFungibleResourcesCollection? = nil, ancestorIdentities: StateEntityDetailsResponseItemAncestorIdentities? = nil, metadata: EntityMetadataCollection, details: StateEntityDetailsResponseItemDetails? = nil) {
			self.address = address
			self.fungibleResources = fungibleResources
			self.nonFungibleResources = nonFungibleResources
			self.ancestorIdentities = ancestorIdentities
			self.metadata = metadata
			self.details = details
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case address
			case fungibleResources = "fungible_resources"
			case nonFungibleResources = "non_fungible_resources"
			case ancestorIdentities = "ancestor_identities"
			case metadata
			case details
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(address, forKey: .address)
			try container.encodeIfPresent(fungibleResources, forKey: .fungibleResources)
			try container.encodeIfPresent(nonFungibleResources, forKey: .nonFungibleResources)
			try container.encodeIfPresent(ancestorIdentities, forKey: .ancestorIdentities)
			try container.encode(metadata, forKey: .metadata)
			try container.encodeIfPresent(details, forKey: .details)
		}
	}
}
