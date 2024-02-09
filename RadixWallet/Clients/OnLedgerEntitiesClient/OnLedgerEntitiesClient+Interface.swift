// MARK: - OnLedgerEntitiesClient
/// A client that manages loading Entities from the Ledger.
public struct OnLedgerEntitiesClient: Sendable {
	/// Retrieve the entities identified by addresses
	public var getEntities: GetEntities

	/// Retrieve the token data associated with the given non fungible ids
	public let getNonFungibleTokenData: GetNonFungibleTokenData

	/// Retrieve the token data associated with the given account.
	public let getAccountOwnedNonFungibleTokenData: GetAccountOwnedNonFungibleTokenData
}

// MARK: - OnLedgerEntitiesClient.GetResources
extension OnLedgerEntitiesClient {
	public typealias GetNonFungibleTokenData = @Sendable (GetNonFungibleTokenDataRequest) async throws -> [OnLedgerEntity.NonFungibleToken]
	public typealias GetAccountOwnedNonFungibleTokenData = @Sendable (GetAccountOwnedNonFungibleTokenDataRequest) async throws -> GetAccountOwnedNonFungibleTokenResponse

	public typealias GetEntities = @Sendable ([EngineToolkitAddress], Set<EntityMetadataKey>, AtLedgerState?, CachingStrategy) async throws -> [OnLedgerEntity]
}

// MARK: OnLedgerEntitiesClient.GetNonFungibleTokenDataRequest
extension OnLedgerEntitiesClient {
	public struct GetAccountOwnedNonFungibleResourceIdsRequest: Sendable {
		/// The address of the account that owns the non fungible resource ids
		public let accountAddress: AccountAddress
		/// The non fungible resource collection for with to retrieve the ids
		public let resource: OnLedgerEntity.OwnedNonFungibleResource
		/// The cursor of the page to read
		public let pageCursor: String?

		public init(
			account: AccountAddress,
			resource: OnLedgerEntity.OwnedNonFungibleResource,
			pageCursor: String?
		) {
			self.accountAddress = account
			self.resource = resource
			self.pageCursor = pageCursor
		}
	}

	public struct GetNonFungibleTokenDataRequest: Sendable {
		/// The ledger state at which to retrieve the data, should be ledger state
		/// from the OnLedgerEntity.OwnedNonFungibleResource.
		public let atLedgerState: AtLedgerState?
		/// The non fungible resource collection to retrieve the ids data for
		public let resource: ResourceAddress
		public let nonFungibleIds: [NonFungibleGlobalId]

		public init(
			atLedgerState: AtLedgerState? = nil,
			resource: ResourceAddress,
			nonFungibleIds: [NonFungibleGlobalId]
		) {
			self.atLedgerState = atLedgerState
			self.resource = resource
			self.nonFungibleIds = nonFungibleIds
		}
	}

	public struct GetAccountOwnedNonFungibleTokenDataRequest: Sendable {
		public enum Mode: Sendable {
			case loadAll
			case loadPage(pageCursor: String?)
		}

		/// The address of the account that owns the non fungible resource ids
		public let accountAddress: AccountAddress
		/// The non fungible resource collection for with to retrieve the ids
		public let resource: OnLedgerEntity.OwnedNonFungibleResource
		/// The page to load, if not provided will load all pages
		public let mode: Mode

		public init(
			accountAddress: AccountAddress,
			resource: OnLedgerEntity.OwnedNonFungibleResource,
			mode: Mode
		) {
			self.accountAddress = accountAddress
			self.resource = resource
			self.mode = mode
		}
	}

	public struct GetAccountOwnedNonFungibleTokenResponse: Sendable {
		public let tokens: [OnLedgerEntity.NonFungibleToken]
		public let nextPageCursor: String?

		public init(
			tokens: [OnLedgerEntity.NonFungibleToken],
			nextPageCursor: String?
		) {
			self.tokens = tokens
			self.nextPageCursor = nextPageCursor
		}
	}
}

// MARK: OnLedgerEntitiesClient.ItemsPage
extension OnLedgerEntitiesClient {
	public struct ItemsPage: Sendable {
		public let cursor: String?
		public let pageLimit: Int

		public init(cursor: String?, pageLimit: Int) {
			self.cursor = cursor
			self.pageLimit = pageLimit
		}
	}
}

extension OnLedgerEntitiesClient {
	public struct CachingStrategy: Sendable, Hashable {
		public enum Read: Sendable, Hashable {
			case fromCache
			case fromLedger
		}

		public enum Write: Sendable, Hashable {
			case toCache
			case skip
		}

		public let read: Read
		public let write: Write

		public static let forceUpdate = Self(read: .fromLedger, write: .toCache)
		public static let useCache = Self(read: .fromCache, write: .toCache)
		public static let readFromLedgerSkipWrite = Self(read: .fromLedger, write: .skip)
	}

	@Sendable
	public func getEntities(
		addresses: [EngineToolkitAddress],
		metadataKeys: Set<EntityMetadataKey>,
		cachingStrategy: CachingStrategy = .useCache,
		atLedgerState: AtLedgerState? = nil
	) async throws -> [OnLedgerEntity] {
		try await getEntities(
			addresses,
			metadataKeys,
			atLedgerState,
			cachingStrategy
		)
	}

	@Sendable
	public func getAccounts(
		_ addresses: [AccountAddress],
		metadataKeys: Set<EntityMetadataKey> = .resourceMetadataKeys,
		cachingStrategy: CachingStrategy = .useCache,
		atLedgerState: AtLedgerState? = nil
	) async throws -> [OnLedgerEntity.Account] {
		try await getEntities(
			addresses: addresses.map(\.asGeneral),
			metadataKeys: metadataKeys,
			cachingStrategy: cachingStrategy,
			atLedgerState: atLedgerState
		).compactMap(\.account)
	}

	@Sendable
	public func getEntity(
		_ address: EngineToolkitAddress,
		metadataKeys: Set<EntityMetadataKey>,
		cachingStrategy: CachingStrategy = .useCache,
		atLedgerState: AtLedgerState? = nil
	) async throws -> OnLedgerEntity {
		guard let entity = try await getEntities(
			addresses: [address],
			metadataKeys: metadataKeys,
			cachingStrategy: cachingStrategy,
			atLedgerState: atLedgerState
		).first else {
			throw Error.emptyResponse
		}

		return entity
	}

	@Sendable
	public func getAccount(
		_ address: AccountAddress,
		metadataKeys: Set<EntityMetadataKey> = .resourceMetadataKeys,
		cachingStrategy: CachingStrategy = .useCache,
		atLedgerState: AtLedgerState? = nil
	) async throws -> OnLedgerEntity.Account {
		guard let account = try await getEntity(
			address.asGeneral,
			metadataKeys: metadataKeys,
			cachingStrategy: cachingStrategy,
			atLedgerState: atLedgerState
		).account else {
			throw Error.emptyResponse
		}
		return account
	}

	@Sendable
	public func getAssociatedDapps(
		_ addresses: [DappDefinitionAddress],
		cachingStrategy: CachingStrategy = .useCache,
		atLedgerState: AtLedgerState? = nil
	) async throws -> [OnLedgerEntity.AssociatedDapp] {
		try await getEntities(
			addresses: addresses.map(\.asGeneral),
			metadataKeys: .dappMetadataKeys,
			cachingStrategy: cachingStrategy,
			atLedgerState: atLedgerState
		)
		.compactMap(\.account)
		.map { .init(address: $0.address, metadata: $0.metadata) }
	}

	@Sendable
	public func getAssociatedDapp(
		_ address: DappDefinitionAddress,
		cachingStrategy: CachingStrategy = .useCache
	) async throws -> OnLedgerEntity.AssociatedDapp {
		guard let dApp = try await getAssociatedDapps(
			[address],
			cachingStrategy: cachingStrategy
		).first else {
			throw Error.emptyResponse
		}
		return dApp
	}

	@Sendable
	public func getResources(
		_ addresses: [ResourceAddress],
		metadataKeys: Set<EntityMetadataKey> = .resourceMetadataKeys,
		cachingStrategy: CachingStrategy = .useCache,
		atLedgerState: AtLedgerState? = nil
	) async throws -> [OnLedgerEntity.Resource] {
		try await getEntities(
			addresses: addresses.map(\.asGeneral),
			metadataKeys: metadataKeys,
			cachingStrategy: cachingStrategy,
			atLedgerState: atLedgerState
		).compactMap(\.resource)
	}

	@Sendable
	public func getResource(
		_ address: ResourceAddress,
		metadataKeys: Set<EntityMetadataKey> = .resourceMetadataKeys,
		atLedgerState: AtLedgerState? = nil
	) async throws -> OnLedgerEntity.Resource {
		guard let resource = try await getResources(
			[address],
			metadataKeys: metadataKeys,
			atLedgerState: atLedgerState
		).first
		else {
			throw Error.emptyResponse
		}
		return resource
	}

	/// Extracts the dApp definition address from an entity, if one is present
	@Sendable
	public func getDappDefinitionAddress(
		_ address: EngineToolkitAddress
	) async throws -> DappDefinitionAddress {
		let entityMetadata = try await getEntity(address, metadataKeys: [.dappDefinition]).metadata
		guard let dappDefinitionAddress = entityMetadata?.dappDefinition else {
			throw OnLedgerEntity.Metadata.MetadataError.missingDappDefinition
		}

		return dappDefinitionAddress
	}

	/// Fetches the metadata for a dApp. If an entity address is supplied, it validates that it is contained in `claimed_entities`
	@Sendable
	public func getDappMetadata(
		_ dappDefinition: DappDefinitionAddress,
		validatingDappEntity entity: EngineToolkitAddress? = nil,
		validatingDappDefinitionAddress dappDefinitionAddress: DappDefinitionAddress? = nil,
		validatingWebsite website: URL? = nil
	) async throws -> OnLedgerEntity.Metadata {
		let forceRefresh = entity != nil || dappDefinitionAddress != nil || website != nil

		let dappMetadata = try await getAssociatedDapp(
			dappDefinition,
			cachingStrategy: forceRefresh ? .forceUpdate : .useCache
		).metadata

		try dappMetadata.validateAccountType()

		if let entity {
			try dappMetadata.validate(dAppEntity: entity)
		}
		if let dappDefinitionAddress {
			try dappMetadata.validate(dAppDefinitionAddress: dappDefinitionAddress)
		}
		if let website {
			try dappMetadata.validate(website: website)
		}

		return dappMetadata
	}
}

// MARK: - OnLedgerSyncOfAccounts
public struct OnLedgerSyncOfAccounts: Sendable, Hashable {
	/// Inactive virtual accounts, unknown to the Ledger OnNetwork.
	public let inactive: IdentifiedArrayOf<Profile.Network.Account>
	/// Accounts known to the Ledger OnNetwork, with state updated according to that OnNetwork.
	public let active: IdentifiedArrayOf<Profile.Network.Account>
}

extension OnLedgerEntitiesClient {
	/// returns the updated account, else `nil` if account was not changed,
	public func syncThirdPartyDepositWithOnLedgerSettings(
		account: Profile.Network.Account
	) async throws -> Profile.Network.Account? {
		guard let ruleOfAccount = try await getOnLedgerCustomizedThirdPartyDepositRule(addresses: [account.address]).first else {
			return nil
		}
		let current = account.onLedgerSettings.thirdPartyDeposits.depositRule
		if ruleOfAccount.rule == current {
			return nil

		} else {
			var account = account
			account.onLedgerSettings.thirdPartyDeposits.depositRule = ruleOfAccount.rule
			return account
		}
	}

	public func syncThirdPartyDepositWithOnLedgerSettings(
		addressesOf accounts: IdentifiedArrayOf<Profile.Network.Account>
	) async throws -> OnLedgerSyncOfAccounts {
		let activeAddresses: [CustomizedOnLedgerThirdPartDepositForAccount]
		do {
			activeAddresses = try await getOnLedgerCustomizedThirdPartyDepositRule(addresses: accounts.map(\.accountAddress))
		} catch is GatewayAPIClient.EmptyEntityDetailsResponse {
			return OnLedgerSyncOfAccounts(inactive: accounts, active: [])
		} catch {
			throw error
		}
		var inactive: IdentifiedArrayOf<Profile.Network.Account> = []
		var active: IdentifiedArrayOf<Profile.Network.Account> = []
		for account in accounts { // iterate with `accounts` to retain insertion order.
			if let onLedgerActiveAccount = activeAddresses.first(where: { $0.address == account.address }) {
				var activeAccount = account
				activeAccount.onLedgerSettings.thirdPartyDeposits.depositRule = onLedgerActiveAccount.rule
				active.append(activeAccount)
			} else {
				inactive.append(account)
			}
		}
		return OnLedgerSyncOfAccounts(inactive: inactive, active: active)
	}

	public struct CustomizedOnLedgerThirdPartDepositForAccount: Sendable, Hashable {
		public let address: AccountAddress
		public let rule: Profile.Network.Account.OnLedgerSettings.ThirdPartyDeposits.DepositRule
	}

	public func getOnLedgerCustomizedThirdPartyDepositRule(
		addresses: some Collection<AccountAddress>
	) async throws -> [CustomizedOnLedgerThirdPartDepositForAccount] {
		try await self.getAccounts(
			Array(addresses),
			metadataKeys: [.ownerBadge, .ownerKeys],
			cachingStrategy: .readFromLedgerSkipWrite
		)
		.compactMap { (onLedgerAccount: OnLedgerEntity.Account) -> CustomizedOnLedgerThirdPartDepositForAccount? in
			let address = onLedgerAccount.address
			guard
				case let metadata = onLedgerAccount.metadata,
				let ownerKeys = metadata.ownerKeys,
				let ownerBadge = metadata.ownerBadge
			else {
				return nil
			}

			func hasStateChange(_ list: OnLedgerEntity.Metadata.ValueAtStateVersion<some Any>) -> Bool {
				list.lastUpdatedAtStateVersion > 0
			}
			let isActive = hasStateChange(ownerKeys) || hasStateChange(ownerBadge)
			guard isActive, let rule = onLedgerAccount.details?.depositRule else {
				return nil
			}
			return CustomizedOnLedgerThirdPartDepositForAccount(address: address, rule: rule)
		}
	}
}

extension OnLedgerEntitiesClient {
	/// Returns the validator of a correctly linked LSU, and `nil` for any other resource
	public func isLiquidStakeUnit(_ resource: OnLedgerEntity.Resource) async -> OnLedgerEntity.Validator? {
		guard let validatorAddress = resource.metadata.validator?.asGeneral else {
			return nil
		}

		// Fetch validator info
		let validator = try? await getEntity(
			validatorAddress,
			metadataKeys: .resourceMetadataKeys,
			cachingStrategy: .useCache,
			atLedgerState: resource.atLedgerState
		)
		.validator

		guard let validator else {
			return nil
		}

		guard validator.stakeUnitResourceAddress == resource.resourceAddress else {
			return nil
		}

		return validator
	}

	public func isPoolUnitResource(_ resource: OnLedgerEntity.Resource) async -> Bool {
		guard let poolAddress = resource.metadata.poolUnit?.asGeneral else {
			return false // no declared pool unit
		}

		// Fetch pool unit info
		let pool = try? await getEntity(
			poolAddress,
			metadataKeys: .poolUnitMetadataKeys,
			cachingStrategy: .useCache,
			atLedgerState: resource.atLedgerState
		).resourcePool

		guard let pool else {
			return false // didn't load any pool
		}

		guard pool.poolUnitResourceAddress == resource.resourceAddress else {
			return false // The resource pool declared a different pool unit resource address
		}

		return true // It is a pool unit resource address
	}

	public func isStakeClaimNFT(_ resource: OnLedgerEntity.Resource) async -> OnLedgerEntity.Validator? {
		guard let validatorAddress = resource.metadata.validator else {
			return nil // no declared pool unit
		}

		let validator = try? await getEntity(
			validatorAddress.asGeneral,
			metadataKeys: .poolUnitMetadataKeys,
			cachingStrategy: .useCache,
			atLedgerState: resource.atLedgerState
		).validator

		guard let validator else {
			return nil
		}

		guard validator.stakeClaimFungibleResourceAddress == resource.resourceAddress else {
			return nil
		}

		return validator
	}
}

extension OnLedgerEntitiesClient {
	public func getPoolUnitDetails(_ poolUnitResource: OnLedgerEntity.Resource, forAmount amount: RETDecimal) async throws -> OwnedResourcePoolDetails? {
		guard let poolAddress = poolUnitResource.metadata.poolUnit?.asGeneral else {
			return nil
		}

		let pool = try? await getEntity(
			poolAddress,
			metadataKeys: .poolUnitMetadataKeys,
			cachingStrategy: .useCache,
			atLedgerState: poolUnitResource.atLedgerState
		).resourcePool

		guard let pool else {
			loggerGlobal.error("Failed to load the resource pool info")
			return nil
		}

		var allResourceAddresses: [ResourceAddress] = []
		allResourceAddresses += pool.resources.nonXrdResources.map(\.resourceAddress)
		if let xrdResource = pool.resources.xrdResource {
			allResourceAddresses.append(xrdResource.resourceAddress)
		}

		let allResources = try? await getResources(
			allResourceAddresses,
			cachingStrategy: .useCache,
			atLedgerState: poolUnitResource.atLedgerState
		).asIdentifiable()

		guard let allResources else {
			loggerGlobal.error("Failed to load the details for the resources in the pool")
			return nil
		}

		let poolUnitResource = ResourceWithVaultAmount(resource: poolUnitResource, amount: amount)

		return await populatePoolDetails(pool, allResources, poolUnitResource)
	}

	// TODO: This function should be uniffied with `getPoolUnitDetails` for a single pool unit resource.
	/// This loads all of the related pool unit details required by the Pool units screen.
	/// We don't do any pagination there(yet), since the number of owned pools will not be big, this can be revised in the future.
	@Sendable
	public func getOwnedPoolUnitsDetails(
		_ account: OnLedgerEntity.Account,
		cachingStrategy: CachingStrategy = .useCache
	) async throws -> [OwnedResourcePoolDetails] {
		let ownedPoolUnits = account.poolUnitResources.poolUnits
		let pools = try await getEntities(
			ownedPoolUnits.map(\.resourcePoolAddress.asGeneral),
			[.dappDefinition],
			account.atLedgerState,
			cachingStrategy
		).compactMap(\.resourcePool)

		var allResourceAddresses: [ResourceAddress] = []
		for pool in pools {
			allResourceAddresses.append(pool.poolUnitResourceAddress)
			allResourceAddresses += pool.resources.nonXrdResources.map(\.resourceAddress)
			if let xrdResource = pool.resources.xrdResource {
				allResourceAddresses.append(xrdResource.resourceAddress)
			}
		}

		let allResources = try await getResources(
			allResourceAddresses,
			cachingStrategy: cachingStrategy,
			atLedgerState: account.atLedgerState
		).asIdentifiable()

		return await ownedPoolUnits.asyncCompactMap { ownedPoolUnit -> OwnedResourcePoolDetails? in
			guard let pool = pools.first(where: { $0.address == ownedPoolUnit.resourcePoolAddress }) else {
				assertionFailure("Did not load pool details")
				return nil
			}
			guard let poolUnitResourcee = allResources.first(where: { $0.resourceAddress == pool.poolUnitResourceAddress }) else {
				assertionFailure("Did not load poolUnitResource details")
				return nil
			}

			let poolUnitResource = ResourceWithVaultAmount(resource: poolUnitResourcee, amount: ownedPoolUnit.resource.amount)

			return await populatePoolDetails(pool, allResources, poolUnitResource)
		}
	}

	private func populatePoolDetails(
		_ pool: OnLedgerEntity.ResourcePool,
		_ allResources: IdentifiedArray<ResourceAddress, OnLedgerEntity.Resource>,
		_ poolUnitResource: OnLedgerEntitiesClient.ResourceWithVaultAmount
	) async -> OnLedgerEntitiesClient.OwnedResourcePoolDetails? {
		var nonXrdResourceDetails: [OwnedResourcePoolDetails.ResourceWithRedemptionValue] = []

		for resource in pool.resources.nonXrdResources {
			guard let resourceDetails = allResources[id: resource.resourceAddress] else {
				assertionFailure("Did not load resource details")
				return nil
			}

			nonXrdResourceDetails.append(.init(
				resource: resourceDetails,
				redemptionValue: resourceDetails.poolRedemptionValue(for: resource.amount, poolUnitResource: poolUnitResource)
			))
		}

		let xrdResourceDetails: OwnedResourcePoolDetails.ResourceWithRedemptionValue?
		if let xrdResource = pool.resources.xrdResource {
			guard let details = allResources[id: xrdResource.resourceAddress] else {
				assertionFailure("Did not load xrd resource details")
				return nil
			}
			xrdResourceDetails = .init(
				resource: details,
				redemptionValue: details.poolRedemptionValue(for: xrdResource.amount, poolUnitResource: poolUnitResource)
			)
		} else {
			xrdResourceDetails = nil
		}

		let dAppName: String? = if let dAppDefinition = pool.metadata.dappDefinition {
			try? await getDappMetadata(dAppDefinition, validatingDappEntity: pool.address.asGeneral).name
		} else {
			nil
		}

		return .init(
			address: pool.address,
			dAppName: dAppName,
			poolUnitResource: poolUnitResource,
			xrdResource: xrdResourceDetails,
			nonXrdResources: nonXrdResourceDetails
		)
	}
}
