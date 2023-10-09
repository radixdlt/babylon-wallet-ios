import EngineKit
import GatewayAPI
import Prelude
import SharedModels

// MARK: - OnLedgerEntitiesClient
/// A client that manages loading Entities from the Ledger.
/// Compared to AccountPortfolio it loads the general info about the entities not related to any account.
/// With a refactor, this can potentially also load the Accounts and then link its resources to the general info about resources.
public struct OnLedgerEntitiesClient: Sendable {
	public let getEntities: GetEntities
	/// Retrieve the token data associated with the given non fungible ids
	public let getNonFungibleTokenData: GetNonFungibleTokenData

	/// Retrieve the account owned ids for a given non fungible resource collection
	public let getAccountOwnedNonFungibleResourceIds: GetAccountOwnedNonFungibleResourceIds

	/// Retrieve the token data associated with the given account.
	/// Basically a combination of `getAccountOwnedNonFungibleResourceIds` and `getNonFungibleTokenData`
	public let getAccountOwnedNonFungibleTokenData: GetAccountOwnedNonFungibleTokenData
}

// MARK: - OnLedgerEntitiesClient.GetResources
extension OnLedgerEntitiesClient {
	public typealias GetNonFungibleTokenData = @Sendable (GetNonFungibleTokenDataRequest) async throws -> [OnLedgerEntity.NonFungibleToken]
	public typealias GetAccountOwnedNonFungibleResourceIds = @Sendable (GetAccountOwnedNonFungibleResourceIdsRequest) async throws -> OnLedgerEntity.AccountNonFungibleIdsPage
	public typealias GetAccountOwnedNonFungibleTokenData = @Sendable (GetAccountOwnedNonFungibleTokenDataRequest) async throws -> [OnLedgerEntity.NonFungibleToken]

	public typealias GetEntities = @Sendable ([Address], Set<EntityMetadataKey>, AtLedgerState?) async throws -> [OnLedgerEntity]
}

// MARK: OnLedgerEntitiesClient.GetNonFungibleTokenDataRequest
extension OnLedgerEntitiesClient {
	public struct GetAccountOwnedNonFungibleResourceIdsRequest: Sendable {
		/// The address of the account that owns the non fungible resource ids
		public let accountAddress: AccountAddress
		/// The non fungible resource collection for with to retrieve the ids
		public let resourceAddress: ResourceAddress
		/// The account vault where the ids are stored
		public let vaultAddress: VaultAddress
		/// The ledger state at which to retrieve the ids, should be ledger state
		/// from the OnLedgerEntity.OwnedNonFungibleResource.
		public let atLedgerState: AtLedgerState
		/// The cursor of the page to read
		public let pageCursor: String?
		/// The page size limit
		public let pageSize: Int?

		public init(
			account: AccountAddress,
			resourceAddress: ResourceAddress,
			vaultAddress: VaultAddress,
			atLedgerState: AtLedgerState,
			pageCursor: String?,
			pageSize: Int = OnLedgerEntitiesClient.maximumNFTIDChunkSize
		) {
			self.accountAddress = account
			self.resourceAddress = resourceAddress
			self.vaultAddress = vaultAddress
			self.atLedgerState = atLedgerState
			self.pageCursor = pageCursor
			self.pageSize = pageSize
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
		/// The address of the account that owns the non fungible resource ids
		public let accountAddress: AccountAddress
		/// The non fungible resource collection for with to retrieve the ids
		public let resource: OnLedgerEntity.OwnedNonFungibleResource

		public init(
			accountAddress: AccountAddress,
			resource: OnLedgerEntity.OwnedNonFungibleResource
		) {
			self.accountAddress = accountAddress
			self.resource = resource
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
	@Sendable
	public func getEntity(_ address: Address, metadataKeys: Set<EntityMetadataKey>) async throws -> OnLedgerEntity {
		guard let resource = try await getEntities([address], metadataKeys, nil).first else {
			throw Error.emptyResponse
		}
		return resource
	}

	@Sendable
	public func getAccounts(_ addresses: [AccountAddress]) async throws -> [OnLedgerEntity.Account] {
		try await getEntities(addresses.map(\.asGeneral), .resourceMetadataKeys, nil).compactMap(\.account)
	}

	@Sendable
	public func getAccount(_ address: AccountAddress, metadataKeys: Set<EntityMetadataKey>) async throws -> OnLedgerEntity.Account {
		guard let account = try await getEntity(address.asGeneral, metadataKeys: metadataKeys).account else {
			throw Error.emptyResponse
		}
		return account
	}

	@Sendable
	public func getResources(_ addresses: [ResourceAddress], metadataKeys: Set<EntityMetadataKey> = .resourceMetadataKeys, atLedgerState: AtLedgerState? = nil) async throws -> [OnLedgerEntity.Resource] {
		try await getEntities(addresses.map(\.asGeneral), metadataKeys, atLedgerState).compactMap(\.resource)
	}

	@Sendable
	public func getResource(_ address: ResourceAddress, metadataKeys: Set<EntityMetadataKey> = .resourceMetadataKeys, atLedgerState: AtLedgerState? = nil) async throws -> OnLedgerEntity.Resource {
		guard let resource = try await getResources([address], metadataKeys: metadataKeys, atLedgerState: atLedgerState).first else {
			throw Error.emptyResponse
		}
		return resource
	}

	/// Extracts the dApp definition address from a component, if one is present
	@Sendable
	public func getDappDefinitionAddress(_ component: ComponentAddress) async throws -> DappDefinitionAddress {
		let entityMetadata = try await getEntity(component.asGeneral, metadataKeys: [.dappDefinition]).genericComponent?.metadata

		guard let dappDefinitionAddress = entityMetadata?.dappDefinition else {
			throw OnLedgerEntity.Metadata.MetadataError.missingDappDefinition
		}

		return dappDefinitionAddress
	}

	/// Fetches the metadata for a dApp. If the component address is supplied, it validates that it is contained in `claimed_entities`
	@Sendable
	public func getDappMetadata(
		_ dappDefinition: DappDefinitionAddress,
		validatingDappComponent component: ComponentAddress? = nil,
		validatingDappDefinitionAddress dappDefinitionAddress: DappDefinitionAddress? = nil,
		validatingWebsite website: URL? = nil
	) async throws -> OnLedgerEntity.Metadata {
		guard let dappMetadata = try await getAccounts([dappDefinition]).first?.metadata else {
			throw Error.emptyResponse
		}

		try dappMetadata.validateAccountType()

		if let component {
			try dappMetadata.validate(dAppComponent: component)
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
