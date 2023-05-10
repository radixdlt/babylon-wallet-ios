import AnyCodable
import Foundation

// MARK: - GatewayAPI.StateEntityDetailsResponse + Sendable
extension GatewayAPI.StateEntityDetailsResponse: @unchecked Sendable {}

// MARK: - GatewayAPI.NonFungibleIdsCollectionItem + Sendable
extension GatewayAPI.NonFungibleIdsCollectionItem: @unchecked Sendable {}

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

extension GatewayAPI.EntityMetadataCollection {
	public enum Key: String {
		case name
		case symbol
		case description
		case iconURL = "icon_url"
		case dappDefinition = "dapp_definition"
		case dappDefinitions = "dapp_definitions"
		case claimedEntities = "claimed_entities"
		case claimedWebsites = "claimed_websites"
		case accountType = "account_type"
	}

	public var name: String? {
		self[.name]?.asString
	}

	public var symbol: String? {
		self[.symbol]?.asString
	}

	public var description: String? {
		self[.description]?.asString
	}

	public var iconURL: URL? {
		self[.iconURL]?.asString.flatMap(URL.init)
	}

	public var dappDefinition: String? {
		self[.dappDefinition]?.asString
	}

	public var dappDefinitions: [String]? {
		self[.dappDefinitions]?.asStringCollection
	}

	public var claimedEntities: [String]? {
		self[.claimedEntities]?.asStringCollection
	}

	public var claimedWebsites: [URL]? {
		self[.claimedWebsites]?.asStringCollection?.compactMap(URL.init)
	}

	public var accountType: AccountType? {
		self[.accountType]?.asString.flatMap(AccountType.init)
	}

	public subscript(key: Key) -> GatewayAPI.EntityMetadataItemValue? {
		items.first { $0.key == key.rawValue }?.value
	}

	public subscript(customKey key: String) -> GatewayAPI.EntityMetadataItemValue? {
		items.first { $0.key == key }?.value
	}

	public enum AccountType: String {
		case dappDefinition = "dapp definition"
	}

	public enum MetadataError: Error, CustomStringConvertible {
		case missingName
		case missingDappDefinition
		case accountTypeNotDappDefinition
		case missingClaimedEntities
		case entityNotClaimed
		case dAppDefinitionNotReciprocating

		public var description: String {
			switch self {
			case .missingName:
				return "The entity has no name"
			case .missingDappDefinition:
				return "The entity has no dApp definition address"
			case .accountTypeNotDappDefinition:
				return "The account is not of the type `dapp definition`"
			case .missingClaimedEntities:
				return "The dapp definition has no claimed_entities key"
			case .entityNotClaimed:
				return "The entity is not claimed by the dApp definition"
			case .dAppDefinitionNotReciprocating:
				return "This dApp definition does not point back to the dApp definition that claims to be associated with it"
			}
		}
	}
}

extension GatewayAPI.StateNonFungibleDataResponse {
	public func nonFungibleData(for nonFungibleId: String) -> AnyCodable? {
		nonFungibleIds.first { $0.nonFungibleId == nonFungibleId }?.mutableData.rawJson
	}
}

extension GatewayAPI.LedgerState {
	public var selector: GatewayAPI.LedgerStateSelector {
		// TODO: Determine what other fields should be sent
		.init(stateVersion: stateVersion)
	}
}
