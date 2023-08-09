import AnyCodable
import EngineKit
import Foundation
import Prelude

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

extension GatewayAPI.EntityMetadataItemValue {
	public var asString: String? {
		typed?.stringValue?.value
	}

	public var asStringCollection: [String]? {
		typed?.stringArrayValue?.values
	}

	public var asURL: URL? {
		(typed?.urlValue?.value).flatMap(URL.init)
	}

	public var asURLCollection: [URL]? {
		typed?.urlArrayValue?.values.compactMap(URL.init)
	}

	public var asOriginCollection: [URL]? {
		typed?.originArrayValue?.values.compactMap(URL.init)
	}

	public var asGlobalAddress: String? {
		typed?.globalAddressValue?.value
	}

	public var asGlobalAddressCollection: [String]? {
		typed?.globalAddressArrayValue?.values
	}

	public var publicKeyHashes: [GatewayAPI.PublicKeyHash]? {
		typed?.publicKeyHashArrayValue?.values
	}
}

extension GatewayAPI.EntityMetadataCollection {
	public var name: String? {
		items[.name]?.asString
	}

	public var symbol: String? {
		items[.symbol]?.asString
	}

	public var description: String? {
		items[.description]?.asString
	}

	public var iconURL: URL? {
		items[.iconURL]?.asURL
	}

	public var dappDefinition: String? {
		items[.dappDefinition]?.asGlobalAddress
	}

	public var dappDefinitions: [String]? {
		items[.dappDefinitions]?.asGlobalAddressCollection
	}

	public var claimedEntities: [String]? {
		items[.claimedEntities]?.asGlobalAddressCollection
	}

	public var claimedWebsites: [URL]? {
		items[.claimedWebsites]?.asOriginCollection
	}

	public var accountType: AccountType? {
		items[.accountType]?.asString.flatMap(AccountType.init)
	}

	public var ownerKeys: [GatewayAPI.PublicKeyHash]? {
		items[.ownerKeys]?.publicKeyHashes
	}

	public var validator: ValidatorAddress? {
		extract(
			key: .validator,
			from: \.asGlobalAddress,
			transform: ValidatorAddress.init(validatingAddress:)
		)
	}

	public var pool: ResourcePoolAddress? {
		extract(
			key: .pool,
			from: \.asGlobalAddress,
			transform: ResourcePoolAddress.init(validatingAddress:)
		)
	}

	public var poolUnitResource: ResourceAddress? {
		extract(
			key: .poolUnit,
			from: \.asGlobalAddress,
			transform: ResourceAddress.init(validatingAddress:)
		)
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

	private func extract<Value, Field>(
		key: EntityMetadataKey,
		from keyPath: KeyPath<GatewayAPI.EntityMetadataItemValue, Field?>,
		transform: @escaping (Field) throws -> Value
	) -> Value? {
		guard let item = items[key] else {
			return nil
		}

		guard let field = item[keyPath: keyPath] else {
			assertionFailure("item found, but it was not wrapped in the expected field")
			return nil
		}

		do {
			return try transform(field)
		} catch {
			assertionFailure(error.localizedDescription)
			return nil
		}
	}
}

// MARK: - EntityMetadataKey
public enum EntityMetadataKey: String, CaseIterable {
	case name
	case symbol
	case description
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
		[.name, .symbol, .description, .iconURL, .validator, .pool, .accountType, .dappDefinition]
	}

	public static var poolUnitMetadataKeys: Set<EntityMetadataKey> {
		resourceMetadataKeys.union([.poolUnit])
	}

	public static var dappMetadataKeys: Set<EntityMetadataKey> {
		[.name, .description, .iconURL, .claimedEntities, .claimedWebsites, .relatedWebsites, .dappDefinitions]
	}
}

extension [GatewayAPI.EntityMetadataItem] {
	public typealias Key = EntityMetadataKey

	public subscript(key: Key) -> GatewayAPI.EntityMetadataItemValue? {
		first { $0.key == key.rawValue }?.value
	}

	public subscript(customKey key: String) -> GatewayAPI.EntityMetadataItemValue? {
		first { $0.key == key }?.value
	}
}

extension GatewayAPI.LedgerState {
	public var selector: GatewayAPI.LedgerStateSelector {
		// TODO: Determine what other fields should be sent
		.init(stateVersion: stateVersion)
	}
}
