// MARK: - OnLedgerEntitiesClient + DependencyKey
extension OnLedgerEntitiesClient: DependencyKey {
	public static let maximumNFTIDChunkSize = 29

	enum Error: Swift.Error {
		case emptyResponse
	}

	public static let liveValue = Self.live()

	public static func live() -> Self {
		Self(
			getEntities: getEntities,
			getNonFungibleTokenData: getNonFungibleData,
			getAccountOwnedNonFungibleTokenData: getAccountOwnedNonFungibleTokenData
		)
	}
}

extension OnLedgerEntitiesClient {
	@Sendable
	@discardableResult
	static func getEntities(
		for addresses: [RETAddress],
		_ explicitMetadata: Set<EntityMetadataKey>,
		ledgerState: AtLedgerState?,
		cachingStrategy: CachingStrategy
	) async throws -> [OnLedgerEntity] {
		try await fetchEntitiesWithCaching(
			for: addresses.map(\.cachingIdentifier),
			cachingStrategy: cachingStrategy,
			refresh: fetchEntites(explicitMetadata, ledgerState: ledgerState)
		)
	}

	@Sendable
	static func getNonFungibleData(_ request: GetNonFungibleTokenDataRequest) async throws -> [OnLedgerEntity.NonFungibleToken] {
		try await fetchEntitiesWithCaching(
			for: request.nonFungibleIds.map { .nonFungibleData($0) },
			cachingStrategy: .useCache,
			refresh: { identifiers in
				try await fetchNonFungibleData(.init(
					atLedgerState: request.atLedgerState,
					resource: request.resource,
					nonFungibleIds: identifiers.compactMap {
						if case let .nonFungibleData(id) = $0 {
							return id
						}
						return nil
					}
				))
			}
		)
		.compactMap(\.nonFungibleToken)
	}

	@Sendable
	static func getNonFungibleResourceIds(
		_ request: GetAccountOwnedNonFungibleResourceIdsRequest
	) async throws -> OnLedgerEntity.AccountNonFungibleIdsPage {
		@Dependency(\.cacheClient) var cacheClient

		let cachingIdentifier = CacheClient.Entry.onLedgerEntity(.nonFungibleIdPage(
			accountAddress: request.accountAddress.asGeneral,
			resourceAddress: request.resource.resourceAddress.asGeneral,
			pageCursor: request.pageCursor
		))
		let cached = try? cacheClient.load(
			OnLedgerEntity.self,
			cachingIdentifier
		) as? OnLedgerEntity

		if let cached = cached?.accountNonFungibleIds {
			return cached
		}

		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		let freshPage = try await gatewayAPIClient.getEntityNonFungibleIdsPage(
			.init(
				atLedgerState: request.resource.atLedgerState.selector,
				cursor: request.pageCursor,
				limitPerPage: maximumNFTIDChunkSize,
				address: request.accountAddress.address,
				vaultAddress: request.resource.vaultAddress.address,
				resourceAddress: request.resource.resourceAddress.address
			)
		)

		let items = try freshPage.items.map {
			try NonFungibleGlobalId.fromParts(
				resourceAddress: request.resource.resourceAddress.intoEngine(),
				nonFungibleLocalId: .from(stringFormat: $0)
			)
		}

		let response = OnLedgerEntity.AccountNonFungibleIdsPage(
			accountAddress: request.accountAddress,
			resourceAddress: request.resource.resourceAddress,
			ids: items,
			pageCursor: request.pageCursor,
			nextPageCursor: freshPage.nextCursor
		)
		cacheClient.save(OnLedgerEntity.accountNonFungibleIds(response), cachingIdentifier)

		return response
	}

	static func getAllNonFungibleResourceIds(_ request: GetAccountOwnedNonFungibleResourceIdsRequest) async throws -> [NonFungibleGlobalId] {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		func collectIds(_ cursor: String?, collectedIds: [NonFungibleGlobalId]) async throws -> [NonFungibleGlobalId] {
			let page = try await getNonFungibleResourceIds(.init(
				account: request.accountAddress,
				resource: request.resource,
				pageCursor: cursor
			))

			let ids = collectedIds + page.ids
			guard let nextPageCursor = page.nextPageCursor else {
				return ids
			}
			return try await collectIds(nextPageCursor, collectedIds: collectedIds)
		}

		return try await collectIds(nil, collectedIds: [])
	}

	@Sendable
	static func getAccountOwnedNonFungibleTokenData(_ request: GetAccountOwnedNonFungibleTokenDataRequest) async throws -> GetAccountOwnedNonFungibleTokenResponse {
		let (ids, nextPageCursor) = try await {
			switch request.mode {
			case let .loadPage(pageCursor):
				let page = try await getNonFungibleResourceIds(.init(
					account: request.accountAddress,
					resource: request.resource,
					pageCursor: pageCursor
				))

				return (page.ids, page.nextPageCursor)

			case .loadAll:
				return try await (
					getAllNonFungibleResourceIds(.init(
						account: request.accountAddress,
						resource: request.resource,
						pageCursor: nil
					)),
					nil
				)
			}
		}()

		let tokens = try await getNonFungibleData(.init(
			atLedgerState: request.resource.atLedgerState,
			resource: request.resource.resourceAddress,
			nonFungibleIds: ids
		))

		return .init(tokens: tokens, nextPageCursor: nextPageCursor)
	}

	static func fetchNonFungibleData(_ request: GetNonFungibleTokenDataRequest) async throws -> [OnLedgerEntity] {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		let response = try await request.nonFungibleIds
			.chunks(ofCount: maximumNFTIDChunkSize)
			.parallelMap { ids in
				try await gatewayAPIClient.getNonFungibleData(.init(
					atLedgerState: request.atLedgerState?.selector,
					resourceAddress: request.resource.address,
					nonFungibleIds: Array(ids.map { try $0.localId().toString() })
				))
			}

		return try response
			.flatMap { item in
				try item.nonFungibleIds.map { id in
					try OnLedgerEntity.nonFungibleToken(.init(
						id: .fromParts(
							resourceAddress: .init(address: request.resource.address),
							nonFungibleLocalId: .from(stringFormat: id.nonFungibleId)
						),
						data: id.data?.programmaticJson.tuple
					))
				}
			}
	}

	@Sendable
	static func fetchEntitiesWithCaching(
		for identifiers: [CacheClient.Entry.OnLedgerEntity],
		cachingStrategy: CachingStrategy,
		refresh: (_ identifiers: [CacheClient.Entry.OnLedgerEntity]) async throws -> [OnLedgerEntity]
	) async throws -> [OnLedgerEntity] {
		@Dependency(\.cacheClient) var cacheClient

		func cacheIfSpecified(_ freshEntities: [OnLedgerEntity]) {
			guard cachingStrategy.write == .toCache else { return }
			for freshEntity in freshEntities {
				cacheClient.save(freshEntity, .onLedgerEntity(freshEntity.cachingIdentifier))
			}
		}

		guard cachingStrategy.read == .fromCache else {
			let freshEntities = try await refresh(Array(identifiers))
			cacheIfSpecified(freshEntities)
			return freshEntities
		}

		let cachedEntities = identifiers.compactMap {
			try? cacheClient.load(OnLedgerEntity.self, .onLedgerEntity($0)) as? OnLedgerEntity
		}

		let notCachedEntities = Set(identifiers).subtracting(Set(cachedEntities.map(\.cachingIdentifier)))
		guard !notCachedEntities.isEmpty else {
			return cachedEntities
		}

		let freshEntities = try await refresh(Array(notCachedEntities))
		cacheIfSpecified(freshEntities)
		return cachedEntities + freshEntities
	}

	@Sendable
	static func fetchEntites(
		_ explicitMetadata: Set<EntityMetadataKey>,
		ledgerState: AtLedgerState?,
		forceRefresh: Bool = false
	) -> (_ entities: [CacheClient.Entry.OnLedgerEntity]) async throws -> [OnLedgerEntity] {
		{ entities in
			guard !entities.isEmpty else {
				return []
			}

			@Dependency(\.gatewayAPIClient) var gatewayAPIClient

			let response = try await gatewayAPIClient.fetchEntitiesDetails(
				entities.map(\.address.address),
				explicitMetadata: explicitMetadata,
				selector: ledgerState?.selector
			)

			return try await response.items.asyncCompactMap { item in
				let allFungibles = try await gatewayAPIClient.fetchAllFungibleResources(
					item,
					ledgerState: response.ledgerState
				)
				let allNonFungibles = try await gatewayAPIClient.fetchAllNonFungibleResources(
					item,
					ledgerState: response.ledgerState
				)

				let updatedItem = GatewayAPI.StateEntityDetailsResponseItem(
					address: item.address,
					fungibleResources: .init(items: allFungibles),
					nonFungibleResources: .init(items: allNonFungibles),
					ancestorIdentities: item.ancestorIdentities,
					metadata: item.metadata,
					explicitMetadata: item.explicitMetadata,
					details: item.details
				)

				return try await createEntity(
					from: updatedItem,
					ledgerState: .init(
						version: response.ledgerState.stateVersion,
						epoch: response.ledgerState.epoch
					)
				)
			}
		}
	}
}

extension OnLedgerEntity {
	var cachingIdentifier: CacheClient.Entry.OnLedgerEntity {
		switch self {
		case let .resource(resource):
			.resource(resource.resourceAddress.asGeneral)
		case let .nonFungibleToken(nonFungibleToken):
			.nonFungibleData(nonFungibleToken.id)
		case let .accountNonFungibleIds(idsPage):
			.nonFungibleIdPage(
				accountAddress: idsPage.accountAddress.asGeneral,
				resourceAddress: idsPage.resourceAddress.asGeneral,
				pageCursor: idsPage.pageCursor
			)
		case let .account(account):
			.account(account.address.asGeneral)
		case let .resourcePool(resourcePool):
			.resourcePool(resourcePool.address.asGeneral)
		case let .validator(validator):
			.validator(validator.address.asGeneral)
		case let .genericComponent(component):
			.genericComponent(component.address.asGeneral)
		}
	}
}

extension CacheClient.Entry.OnLedgerEntity {
	var address: RETAddress {
		switch self {
		case let .resource(resource):
			resource.asGeneral
		case let .account(account):
			account.asGeneral
		case let .resourcePool(resourcePool):
			resourcePool.asGeneral
		case let .validator(validator):
			validator.asGeneral
		case let .genericComponent(genericComponent):
			genericComponent.asGeneral
		case let .nonFungibleData(nonFungibleId):
			.init(
				address: nonFungibleId.resourceAddress().asStr(),
				decodedKind: .globalNonFungibleResourceManager
			)
		case let .nonFungibleIdPage(_, resourceAddress, _):
			resourceAddress.asGeneral
		}
	}
}

extension RETAddress {
	var cachingIdentifier: CacheClient.Entry.OnLedgerEntity {
		switch self.decodedKind {
		case _ where AccountEntityType.addressSpace.contains(self.decodedKind):
			.account(self)
		case _ where ResourceEntityType.addressSpace.contains(self.decodedKind):
			.resource(self)
		case _ where ResourcePoolEntityType.addressSpace.contains(self.decodedKind):
			.resourcePool(self)
		case _ where ValidatorEntityType.addressSpace.contains(self.decodedKind):
			.validator(self)
		case _ where ComponentEntityType.addressSpace.contains(self.decodedKind):
			.genericComponent(self)
		default:
			.genericComponent(self)
		}
	}
}

extension OnLedgerEntity.Account.PoolUnitResources {
	// The fungible resources used to build up the pool units.
	// Will be used to filter out those from the general fungible resources list.
	var fungibleResourceAddresses: [ResourceAddress] {
		radixNetworkStakes.compactMap(\.stakeUnitResource?.resourceAddress) +
			poolUnits.map(\.resource.resourceAddress)
	}

	// The non fungible resources used to build up the pool units.
	// Will be used to filter out those from the general fungible resources list.
	var nonFungibleResourceAddresses: [ResourceAddress] {
		radixNetworkStakes.compactMap(\.stakeClaimResource?.resourceAddress)
	}
}

extension AtLedgerState {
	public var selector: GatewayAPI.LedgerStateSelector {
		.init(stateVersion: self.version)
	}
}
