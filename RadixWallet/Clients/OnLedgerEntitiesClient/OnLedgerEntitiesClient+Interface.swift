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

	public typealias GetEntities = @Sendable ([Address], Set<EntityMetadataKey>, AtLedgerState?, _ forceRefresh: Bool) async throws -> [OnLedgerEntity]
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
	@Sendable
	public func getEntity(
		_ address: Address,
		metadataKeys: Set<EntityMetadataKey>,
		forceRefresh: Bool = false
	) async throws -> OnLedgerEntity {
		guard let resource = try await getEntities([address], metadataKeys, nil, forceRefresh).first else {
			throw Error.emptyResponse
		}
		return resource
	}

	@Sendable
	public func getAccounts(
		_ addresses: [AccountAddress],
		forceRefresh: Bool = false
	) async throws -> [OnLedgerEntity.Account] {
		try await getEntities(addresses.map(\.asGeneral), .resourceMetadataKeys, nil, forceRefresh).compactMap(\.account)
	}

	@Sendable
	public func getAccount(
		_ address: AccountAddress,
		metadataKeys: Set<EntityMetadataKey> = .resourceMetadataKeys
	) async throws -> OnLedgerEntity.Account {
		guard let account = try await getEntity(address.asGeneral, metadataKeys: metadataKeys).account else {
			throw Error.emptyResponse
		}
		return account
	}

	@Sendable
	public func getAssociatedDapps(_ addresses: [DappDefinitionAddress]) async throws -> [OnLedgerEntity.AssociatedDapp] {
		try await getEntities(addresses.map(\.asGeneral), .dappMetadataKeys, nil, false)
			.compactMap(\.account)
			.map {
				.init(address: $0.address, metadata: $0.metadata)
			}
	}

	@Sendable
	public func getAssociatedDapp(_ address: DappDefinitionAddress) async throws -> OnLedgerEntity.AssociatedDapp {
		guard let dApp = try await getAssociatedDapps([address]).first else {
			throw Error.emptyResponse
		}
		return dApp
	}

	@Sendable
	public func getResources(
		_ addresses: [ResourceAddress],
		metadataKeys: Set<EntityMetadataKey> = .resourceMetadataKeys,
		atLedgerState: AtLedgerState? = nil,
		forceRefresh: Bool = false
	) async throws -> [OnLedgerEntity.Resource] {
		try await getEntities(addresses.map(\.asGeneral), metadataKeys, atLedgerState, forceRefresh).compactMap(\.resource)
	}

	@Sendable
	public func getResource(
		_ address: ResourceAddress,
		metadataKeys: Set<EntityMetadataKey> = .resourceMetadataKeys,
		atLedgerState: AtLedgerState? = nil
	) async throws -> OnLedgerEntity.Resource {
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
		let dappMetadata = try await getAssociatedDapp(dappDefinition).metadata

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
