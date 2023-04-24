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
	public var description: String? {
		self["description"]?.asString
	}

	public var symbol: String? {
		self["symbol"]?.asString
	}

	public var name: String? {
		self["name"]?.asString
	}

	public var domain: String? {
		self["domain"]?.asString
	}

	public var url: String? {
		self["url"]?.asString
	}

	public var dappDefinition: String? {
		self["dapp_definition"]?.asString
	}

	public var claimedEntities: [String]? {
		self["claimed_entities"]?.asStringCollection
	}

	public var claimedWebsites: [String]? {
		self["claimed_websites"]?.asStringCollection
	}

	public var accountType: AccountType? {
		self["account_type"]?.asString.flatMap(AccountType.init)
	}

	public var iconURL: URL? {
		self["icon_url"]?.asString.flatMap(URL.init)
	}

	public subscript(key: String) -> GatewayAPI.EntityMetadataItemValue? {
		items.first { $0.key == key }?.value
	}

	public enum AccountType: String {
		case dappDefinition = "dapp definition"
	}

	public enum MetadataError: Error, CustomStringConvertible {
		case missingDappDefinition
		case accountTypeNotDappDefinition
		case missingClaimedEntities
		case entityNotClaimed

		public var description: String {
			switch self {
			case .missingDappDefinition:
				return "The entity has no dApp definition address"
			case .accountTypeNotDappDefinition:
				return "The account is not of the type `dapp definition`"
			case .missingClaimedEntities:
				return "The dapp definition has no claimed_entities key"
			case .entityNotClaimed:
				return "The entity is not claimed by the dapp definition"
			}
		}
	}
}

extension GatewayAPI.LedgerState {
	public var selector: GatewayAPI.LedgerStateSelector {
		// TODO: Determine what other fields should be sent
		.init(stateVersion: stateVersion)
	}
}
