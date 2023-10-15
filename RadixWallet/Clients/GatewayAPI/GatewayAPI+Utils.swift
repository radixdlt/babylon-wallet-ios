// MARK: - GatewayAPI.StateEntityDetailsResponse + Sendable
extension GatewayAPI.StateEntityDetailsResponse: @unchecked Sendable {}

// MARK: - GatewayAPI.NonFungibleResourcesCollectionItemVaultAggregatedVaultItem + Sendable
extension GatewayAPI.NonFungibleResourcesCollectionItemVaultAggregatedVaultItem: @unchecked Sendable {}

// MARK: - GatewayAPI.NonFungibleResourcesCollectionItem + Sendable
extension GatewayAPI.NonFungibleResourcesCollectionItem: @unchecked Sendable {}

// MARK: - GatewayAPI.FungibleResourcesCollectionItemVaultAggregatedVaultItem + Sendable
extension GatewayAPI.FungibleResourcesCollectionItemVaultAggregatedVaultItem: @unchecked Sendable {}

// MARK: - GatewayAPI.FungibleResourcesCollectionItem + Sendable
extension GatewayAPI.FungibleResourcesCollectionItem: @unchecked Sendable {}

// MARK: - GatewayAPI.LedgerState + Sendable
extension GatewayAPI.LedgerState: @unchecked Sendable {}

// MARK: - GatewayAPI.StateEntityDetailsResponseItem + Sendable
extension GatewayAPI.StateEntityDetailsResponseItem: @unchecked Sendable {}

// MARK: - GatewayAPI.FungibleResourcesCollectionItemVaultAggregated + Sendable
extension GatewayAPI.FungibleResourcesCollectionItemVaultAggregated: @unchecked Sendable {}

// MARK: - GatewayAPI.NonFungibleResourcesCollectionItemVaultAggregated + Sendable
extension GatewayAPI.NonFungibleResourcesCollectionItemVaultAggregated: @unchecked Sendable {}

extension GatewayAPI.StateEntityDetailsResponseItemDetails {
	public var fungible: GatewayAPI.StateEntityDetailsResponseFungibleResourceDetails? {
		if case let .fungibleResource(details) = self {
			return details
		}
		return nil
	}

	public var nonFungible: GatewayAPI.StateEntityDetailsResponseNonFungibleResourceDetails? {
		if case let .nonFungibleResource(details) = self {
			return details
		}
		return nil
	}
}

// MARK: - EntityMetadataKey
public enum EntityMetadataKey: String, CaseIterable {
	case name
	case symbol
	case description
	case tags
	case iconURL = "icon_url"
	case dappDefinition = "dapp_definition"
	case validator
	case pool
	case poolUnit = "pool_unit"
	case dappDefinitions = "dapp_definitions"
	case claimedEntities = "claimed_entities"
	case claimedWebsites = "claimed_websites"
	case relatedWebsites = "related_websites"
	case accountType = "account_type"
	case ownerKeys = "owner_keys"

	// The GW limits the number of metadata keys we can ask for
	static var maxAllowedKeys = 10
}

extension Set<EntityMetadataKey> {
	public static var resourceMetadataKeys: Set<EntityMetadataKey> {
		[.name, .symbol, .description, .iconURL, .validator, .pool, .accountType, .tags, .dappDefinition, .dappDefinitions]
	}

	public static var poolUnitMetadataKeys: Set<EntityMetadataKey> {
		[.name, .description, .iconURL, .poolUnit]
	}

	public static var dappMetadataKeys: Set<EntityMetadataKey> {
		[.name, .description, .iconURL, .claimedEntities, .claimedWebsites, .relatedWebsites, .dappDefinitions, .accountType]
	}
}

extension GatewayAPI.LedgerState {
	public var selector: GatewayAPI.LedgerStateSelector {
		// TODO: Determine what other fields should be sent
		.init(stateVersion: stateVersion)
	}
}

extension GatewayAPI.StateEntityDetailsResponseComponentDetails {
	public func decodeState<State: Decodable>() throws -> State? {
		guard let state else {
			return nil
		}
		let data = try JSONSerialization.data(withJSONObject: state.value)
		return try JSONDecoder().decode(State.self, from: data)
	}
}
