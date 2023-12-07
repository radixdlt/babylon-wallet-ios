// MARK: - OnLedgerEntity
public enum OnLedgerEntity: Sendable, Hashable, Codable {
	case resource(Resource)
	case account(Account)
	case resourcePool(ResourcePool)
	case validator(Validator)
	case nonFungibleToken(NonFungibleToken)
	case accountNonFungibleIds(AccountNonFungibleIdsPage)
	case genericComponent(GenericComponent)

	public var resource: Resource? {
		guard case let .resource(resource) = self else {
			return nil
		}
		return resource
	}

	public var nonFungibleToken: NonFungibleToken? {
		guard case let .nonFungibleToken(nonFungibleToken) = self else {
			return nil
		}
		return nonFungibleToken
	}

	public var accountNonFungibleIds: AccountNonFungibleIdsPage? {
		guard case let .accountNonFungibleIds(ids) = self else {
			return nil
		}
		return ids
	}

	public var account: Account? {
		guard case let .account(account) = self else {
			return nil
		}
		return account
	}

	public var resourcePool: ResourcePool? {
		guard case let .resourcePool(resourcePool) = self else {
			return nil
		}
		return resourcePool
	}

	public var validator: Validator? {
		guard case let .validator(validator) = self else {
			return nil
		}
		return validator
	}

	public var genericComponent: GenericComponent? {
		guard case let .genericComponent(genericComponent) = self else {
			return nil
		}
		return genericComponent
	}
}

// MARK: OnLedgerEntity.Resource
extension OnLedgerEntity {
	public struct Metadata: Sendable, Hashable, Codable {
		public enum PublicKeyHash: Sendable, Hashable, Codable {
			case ecdsaSecp256k1(String)
			case eddsaEd25519(String)
		}

		public let name: String?
		public let symbol: String?
		public let description: String?
		public let iconURL: URL?
		public let tags: [AssetTag]
		public let dappDefinitions: [AccountAddress]?
		public let dappDefinition: AccountAddress?
		public let validator: ValidatorAddress?
		public let poolUnit: ResourcePoolAddress?
		public let poolUnitResource: ResourceAddress?
		public let claimedEntities: [String]?
		public let claimedWebsites: [URL]?
		public let accountType: AccountType?
		public let ownerKeys: [PublicKeyHash]?

		public init(
			name: String? = nil,
			symbol: String? = nil,
			description: String? = nil,
			iconURL: URL? = nil,
			tags: [AssetTag] = [],
			dappDefinitions: [AccountAddress]? = nil,
			dappDefinition: AccountAddress? = nil,
			validator: ValidatorAddress? = nil,
			poolUnit: ResourcePoolAddress? = nil,
			poolUnitResource: ResourceAddress? = nil,
			claimedEntities: [String]? = nil,
			claimedWebsites: [URL]? = nil,
			accountType: AccountType? = nil,
			ownerKeys: [PublicKeyHash]? = nil
		) {
			self.name = name
			self.symbol = symbol
			self.description = description
			self.iconURL = iconURL
			self.tags = tags
			self.dappDefinitions = dappDefinitions
			self.dappDefinition = dappDefinition
			self.validator = validator
			self.poolUnit = poolUnit
			self.poolUnitResource = poolUnitResource
			self.claimedEntities = claimedEntities
			self.claimedWebsites = claimedWebsites
			self.accountType = accountType
			self.ownerKeys = ownerKeys
		}
	}

	// MARK: - AccountType
	public enum AccountType: String, Sendable, Codable {
		case dappDefinition = "dapp definition"
	}

	public struct Resource: Sendable, Hashable, Codable, Identifiable {
		public var id: ResourceAddress { resourceAddress }
		public let resourceAddress: ResourceAddress
		public let atLedgerState: AtLedgerState
		public let divisibility: Int?
		public let behaviors: [AssetBehavior]
		public let totalSupply: RETDecimal?
		public let metadata: Metadata

		public var fungibility: Fungibility {
			if case .globalFungibleResourceManager = resourceAddress.decodedKind {
				.fungible
			} else {
				.nonFungible
			}
		}

		public enum Fungibility {
			case fungible
			case nonFungible
		}

		public init(
			resourceAddress: ResourceAddress,
			atLedgerState: AtLedgerState,
			divisibility: Int? = nil,
			behaviors: [AssetBehavior] = [],
			totalSupply: RETDecimal? = nil,
			metadata: Metadata
		) {
			self.resourceAddress = resourceAddress
			self.atLedgerState = atLedgerState
			self.divisibility = divisibility
			self.behaviors = behaviors
			self.totalSupply = totalSupply
			self.metadata = metadata
		}
	}

	public struct GenericComponent: Sendable, Hashable, Codable {
		public let address: ComponentAddress
		public let atLedgerState: AtLedgerState
		public let behaviors: [AssetBehavior]
		public let metadata: Metadata

		public init(
			address: ComponentAddress,
			atLedgerState: AtLedgerState,
			behaviors: [AssetBehavior],
			metadata: Metadata
		) {
			self.address = address
			self.atLedgerState = atLedgerState
			self.behaviors = behaviors
			self.metadata = metadata
		}
	}
}

extension OnLedgerEntity {
	public struct NonFungibleToken: Sendable, Hashable, Identifiable, Codable {
		public typealias NFTData = GatewayAPI.ProgrammaticScryptoSborValueTuple
		public let id: NonFungibleGlobalId
		public let data: NFTData?

		public init(
			id: NonFungibleGlobalId,
			data: NFTData?
		) {
			self.id = id
			self.data = data
		}
	}

	public struct AccountNonFungibleIdsPage: Sendable, Hashable, Codable {
		public let accountAddress: AccountAddress
		public let resourceAddress: ResourceAddress
		public let ids: [NonFungibleGlobalId]
		public let pageCursor: String?
		public let nextPageCursor: String?

		public init(
			accountAddress: AccountAddress,
			resourceAddress: ResourceAddress,
			ids: [NonFungibleGlobalId],
			pageCursor: String?,
			nextPageCursor: String?
		) {
			self.accountAddress = accountAddress
			self.resourceAddress = resourceAddress
			self.ids = ids
			self.pageCursor = pageCursor
			self.nextPageCursor = nextPageCursor
		}
	}
}

extension OnLedgerEntity {
	public struct ResourcePool: Sendable, Hashable, Codable {
		public let address: ResourcePoolAddress
		public let poolUnitResourceAddress: ResourceAddress
		public let resources: OwnedFungibleResources
		public let metadata: Metadata

		public init(
			address: ResourcePoolAddress,
			poolUnitResourceAddress: ResourceAddress,
			resources: OwnedFungibleResources,
			metadata: Metadata
		) {
			self.address = address
			self.poolUnitResourceAddress = poolUnitResourceAddress
			self.resources = resources
			self.metadata = metadata
		}
	}

	public struct Validator: Sendable, Hashable, Codable {
		public let address: ValidatorAddress
		public let stakeUnitResourceAddress: ResourceAddress
		public let xrdVaultBalance: RETDecimal
		public let stakeClaimFungibleResourceAddress: ResourceAddress
		public let metadata: Metadata

		public init(
			address: ValidatorAddress,
			stakeUnitResourceAddress: ResourceAddress,
			xrdVaultBalance: RETDecimal,
			stakeClaimFungibleResourceAddress: ResourceAddress,
			metadata: Metadata
		) {
			self.address = address
			self.stakeUnitResourceAddress = stakeUnitResourceAddress
			self.xrdVaultBalance = xrdVaultBalance
			self.stakeClaimFungibleResourceAddress = stakeClaimFungibleResourceAddress
			self.metadata = metadata
		}
	}
}

extension OnLedgerEntity {
	public struct OwnedFungibleResources: Sendable, Hashable, Codable {
		public let xrdResource: OwnedFungibleResource?
		public let nonXrdResources: [OwnedFungibleResource]

		public init(xrdResource: OwnedFungibleResource? = nil, nonXrdResources: [OwnedFungibleResource] = []) {
			self.xrdResource = xrdResource
			self.nonXrdResources = nonXrdResources
		}
	}

	public struct OwnedFungibleResource: Sendable, Hashable, Identifiable, Codable {
		public var id: ResourceAddress {
			resourceAddress
		}

		public let resourceAddress: ResourceAddress
		public let atLedgerState: AtLedgerState
		public let amount: RETDecimal
		public let metadata: Metadata

		public init(
			resourceAddress: ResourceAddress,
			atLedgerState: AtLedgerState,
			amount: RETDecimal,
			metadata: Metadata
		) {
			self.resourceAddress = resourceAddress
			self.atLedgerState = atLedgerState
			self.amount = amount
			self.metadata = metadata
		}
	}

	public struct OwnedNonFungibleResource: Sendable, Hashable, Identifiable, Codable {
		public var id: ResourceAddress {
			resourceAddress
		}

		public let resourceAddress: ResourceAddress
		public let atLedgerState: AtLedgerState
		public let metadata: Metadata
		public let nonFungibleIdsCount: Int
		/// The vault where the owned ids are stored
		public let vaultAddress: VaultAddress

		public init(
			resourceAddress: ResourceAddress,
			atLedgerState: AtLedgerState,
			metadata: Metadata,
			nonFungibleIdsCount: Int,
			vaultAddress: VaultAddress
		) {
			self.resourceAddress = resourceAddress
			self.atLedgerState = atLedgerState
			self.metadata = metadata
			self.nonFungibleIdsCount = nonFungibleIdsCount
			self.vaultAddress = vaultAddress
		}
	}
}

// MARK: OnLedgerEntity.Account
extension OnLedgerEntity {
	public struct Account: Sendable, Hashable, Codable {
		public let address: AccountAddress
		public let atLedgerState: AtLedgerState
		public let metadata: Metadata
		public var fungibleResources: OwnedFungibleResources
		public var nonFungibleResources: [OwnedNonFungibleResource]
		public var poolUnitResources: PoolUnitResources

		public init(
			address: AccountAddress,
			atLedgerState: AtLedgerState,
			metadata: Metadata,
			fungibleResources: OwnedFungibleResources,
			nonFungibleResources: [OwnedNonFungibleResource],
			poolUnitResources: PoolUnitResources
		) {
			self.address = address
			self.atLedgerState = atLedgerState
			self.metadata = metadata
			self.fungibleResources = fungibleResources
			self.nonFungibleResources = nonFungibleResources
			self.poolUnitResources = poolUnitResources
		}
	}
}

// MARK: OnLedgerEntity.AssociatedDapp
extension OnLedgerEntity {
	public struct AssociatedDapp: Sendable, Hashable, Codable {
		public let address: DappDefinitionAddress
		public let metadata: Metadata

		public init(address: DappDefinitionAddress, metadata: Metadata) {
			self.address = address
			self.metadata = metadata
		}
	}
}

extension OnLedgerEntity.Account {
	public struct PoolUnitResources: Sendable, Hashable, Codable {
		public let radixNetworkStakes: [RadixNetworkStake]
		public let poolUnits: [PoolUnit]

		public init(radixNetworkStakes: [RadixNetworkStake], poolUnits: [PoolUnit]) {
			self.radixNetworkStakes = radixNetworkStakes
			self.poolUnits = poolUnits
		}
	}

	public struct RadixNetworkStake: Sendable, Hashable, Codable {
		public let validatorAddress: ValidatorAddress
		public let stakeUnitResource: OnLedgerEntity.OwnedFungibleResource?
		public let stakeClaimResource: OnLedgerEntity.OwnedNonFungibleResource?

		public init(
			validatorAddress: ValidatorAddress,
			stakeUnitResource: OnLedgerEntity.OwnedFungibleResource?,
			stakeClaimResource: OnLedgerEntity.OwnedNonFungibleResource?
		) {
			self.validatorAddress = validatorAddress
			self.stakeUnitResource = stakeUnitResource
			self.stakeClaimResource = stakeClaimResource
		}
	}

	public struct PoolUnit: Sendable, Hashable, Codable {
		public let resource: OnLedgerEntity.OwnedFungibleResource
		public let resourcePoolAddress: ResourcePoolAddress

		public init(
			resource: OnLedgerEntity.OwnedFungibleResource,
			resourcePoolAddress: ResourcePoolAddress
		) {
			self.resource = resource
			self.resourcePoolAddress = resourcePoolAddress
		}
	}
}

// MARK: - OnLedgerEntity.NonFungibleToken.NFTData
extension OnLedgerEntity.NonFungibleToken.NFTData {
	public enum StandardField: String, Sendable, Hashable, Codable, CaseIterable {
		case name
		case description
		case keyImageURL = "key_image_url"
		case claimEpoch = "claim_epoch"
		case claimAmount = "claim_amount"
	}

	public func getString(forField field: StandardField) -> String? {
		self.fields.compactMap(/GatewayAPI.ProgrammaticScryptoSborValue.string).first {
			$0.fieldName == field.rawValue
		}?.value
	}

	public func getU64Value(forField field: StandardField) -> UInt64? {
		for f in fields {
			if case let .u64(u64) = f, u64.fieldName == field.rawValue {
				return UInt64(u64.value)
			}
		}
		return nil
	}

	public func getDecimalValue(forField field: StandardField) -> RETDecimal? {
		self.fields
			.compactMap(/GatewayAPI.ProgrammaticScryptoSborValue.decimal)
			.first { $0.fieldName == field.rawValue }
			.flatMap { try? RETDecimal(value: $0.value) }
	}

	public var name: String? {
		getString(forField: .name)
	}

	public var tokenDescription: String? {
		getString(forField: .description)
	}

	public var keyImageURL: URL? {
		getString(forField: .keyImageURL).flatMap(URL.init(string:))
	}

	public var claimAmount: RETDecimal? {
		getDecimalValue(forField: .claimAmount)
	}

	public var claimEpoch: UInt64? {
		getU64Value(forField: .claimEpoch)
	}
}

extension OnLedgerEntity.Account {
	public var allFungibleResourceAddresses: [ResourceAddress] {
		fungibleResources.xrdResource.asArray(\.resourceAddress) + fungibleResources.nonXrdResources.map(\.resourceAddress)
	}

	public var allResourceAddresses: Set<ResourceAddress> {
		Set(
			allFungibleResourceAddresses
				+ nonFungibleResources.map(\.resourceAddress)
				+ poolUnitResources.fungibleResourceAddresses
				+ poolUnitResources.nonFungibleResourceAddresses
		)
	}

	public func hasResource(_ resourceAddress: ResourceAddress) -> Bool {
		allResourceAddresses.contains(resourceAddress)
	}
}
