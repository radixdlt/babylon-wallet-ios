// MARK: - GatewayAPI.StateEntityDetailsResponse + @unchecked Sendable
extension GatewayAPI.StateEntityDetailsResponse: @unchecked Sendable {}

// MARK: - GatewayAPI.NonFungibleResourcesCollectionItemVaultAggregatedVaultItem + @unchecked Sendable
extension GatewayAPI.NonFungibleResourcesCollectionItemVaultAggregatedVaultItem: @unchecked Sendable {}

// MARK: - GatewayAPI.NonFungibleResourcesCollectionItem + @unchecked Sendable
extension GatewayAPI.NonFungibleResourcesCollectionItem: @unchecked Sendable {}

// MARK: - GatewayAPI.FungibleResourcesCollectionItemVaultAggregatedVaultItem + @unchecked Sendable
extension GatewayAPI.FungibleResourcesCollectionItemVaultAggregatedVaultItem: @unchecked Sendable {}

// MARK: - GatewayAPI.FungibleResourcesCollectionItem + @unchecked Sendable
extension GatewayAPI.FungibleResourcesCollectionItem: @unchecked Sendable {}

// MARK: - GatewayAPI.LedgerState + @unchecked Sendable
extension GatewayAPI.LedgerState: @unchecked Sendable {}

// MARK: - GatewayAPI.StateEntityDetailsResponseItem + @unchecked Sendable
extension GatewayAPI.StateEntityDetailsResponseItem: @unchecked Sendable {}

// MARK: - GatewayAPI.FungibleResourcesCollectionItemVaultAggregated + @unchecked Sendable
extension GatewayAPI.FungibleResourcesCollectionItemVaultAggregated: @unchecked Sendable {}

// MARK: - GatewayAPI.NonFungibleResourcesCollectionItemVaultAggregated + @unchecked Sendable
extension GatewayAPI.NonFungibleResourcesCollectionItemVaultAggregated: @unchecked Sendable {}

// MARK: - GatewayAPI.EntityMetadataItem + @unchecked Sendable
extension GatewayAPI.EntityMetadataItem: @unchecked Sendable {}

// MARK: - GatewayAPI.AccountLockerVaultCollectionItem + @unchecked Sendable
extension GatewayAPI.AccountLockerVaultCollectionItem: @unchecked Sendable {}

// MARK: - GatewayAPI.StateAccountLockersTouchedAtResponse + @unchecked Sendable
extension GatewayAPI.StateAccountLockersTouchedAtResponse: @unchecked Sendable {}

extension GatewayAPI.StateEntityDetailsResponseItemDetails {
	var fungible: GatewayAPI.StateEntityDetailsResponseFungibleResourceDetails? {
		if case let .fungibleResource(details) = self {
			return details
		}
		return nil
	}

	var nonFungible: GatewayAPI.StateEntityDetailsResponseNonFungibleResourceDetails? {
		if case let .nonFungibleResource(details) = self {
			return details
		}
		return nil
	}
}

// MARK: - EntityMetadataKey
enum EntityMetadataKey: String, CaseIterable, Sendable {
	case name
	case symbol
	case description
	case tags
	case iconURL = "icon_url"
	case infoURL = "info_url"
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
	case ownerBadge = "owner_badge"

	// The GW limits the number of metadata keys we can ask for
	static let maxAllowedKeys = 11
}

extension Set<EntityMetadataKey> {
	static var resourceMetadataKeys: Set<EntityMetadataKey> {
		let keys: Set<EntityMetadataKey> = [.name, .symbol, .description, .iconURL, .infoURL, .validator, .pool, .accountType, .tags, .dappDefinition, .dappDefinitions]
		assert(keys.count <= EntityMetadataKey.maxAllowedKeys)
		return keys
	}

	static var poolUnitMetadataKeys: Set<EntityMetadataKey> {
		let keys: Set<EntityMetadataKey> = [.name, .description, .iconURL, .poolUnit]
		assert(keys.count <= EntityMetadataKey.maxAllowedKeys)
		return keys
	}

	static var dappMetadataKeys: Set<EntityMetadataKey> {
		let keys: Set<EntityMetadataKey> = [.name, .description, .iconURL, .claimedEntities, .claimedWebsites, .relatedWebsites, .dappDefinitions, .accountType, .tags]
		assert(keys.count <= EntityMetadataKey.maxAllowedKeys)
		return keys
	}
}

extension GatewayAPI.LedgerState {
	var selector: GatewayAPI.LedgerStateSelector {
		// TODO: Determine what other fields should be sent
		.init(stateVersion: stateVersion)
	}
}

extension GatewayAPI.StateEntityDetailsResponseComponentDetails {
	func decodeState<State: Decodable>() throws -> State? {
		guard let state else {
			return nil
		}
		let data = try JSONSerialization.data(withJSONObject: state.value)
		return try JSONDecoder().decode(State.self, from: data)
	}
}
