import Sargon

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
		for addresses: [Address],
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
			accountAddress: request.accountAddress,
			resourceAddress: request.resource.resourceAddress,
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
			try NonFungibleGlobalId(
				resourceAddress: request.resource.resourceAddress,
				nonFungibleLocalId: .init($0)
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
					nonFungibleIds: Array(ids.map { $0.nonFungibleLocalId.toRawString() })
				))
			}

		return try response
			.flatMap { item in
				try item.nonFungibleIds.map { id in
					try OnLedgerEntity.nonFungibleToken(.init(
						id: NonFungibleGlobalID(
							resourceAddress: request.resource,
							nonFungibleLocalId: .init(id.nonFungibleId)
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

				var allMetadataItems = Set(item.metadata.items)
				if let nextCursor = item.metadata.nextCursor {
					// Only fetch metadata if there is more after the first page returned.
					let remaining = try await gatewayAPIClient.fetchEntityMetadata(item.address, ledgerState: response.ledgerState, nextCursor: nextCursor)
					allMetadataItems.append(contentsOf: remaining)
				}

				let updatedItem = GatewayAPI.StateEntityDetailsResponseItem(
					address: item.address,
					fungibleResources: .init(items: allFungibles),
					nonFungibleResources: .init(items: allNonFungibles),
					ancestorIdentities: item.ancestorIdentities,
					metadata: .init(totalCount: Int64(allMetadataItems.count), items: Array(allMetadataItems)),
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
			.init(address: resource.resourceAddress)
		case let .nonFungibleToken(nonFungibleToken):
			.nonFungibleData(nonFungibleToken.id)
		case let .accountNonFungibleIds(idsPage):
			.nonFungibleIdPage(
				accountAddress: idsPage.accountAddress,
				resourceAddress: idsPage.resourceAddress,
				pageCursor: idsPage.pageCursor
			)
		case let .account(account):
			.init(address: account.address)
		case let .resourcePool(resourcePool):
			.init(address: resourcePool.address)
		case let .validator(validator):
			.init(address: validator.address)
		case let .genericComponent(component):
			.init(address: component.address)
		}
	}
}

extension CacheClient.Entry.OnLedgerEntity {
	var address: Address {
		switch self {
		case let .address(address): address
		case let .nonFungibleData(globalID): globalID.resourceAddress.asGeneral
		case let .nonFungibleIdPage(_, resourceAddress, _): resourceAddress.asGeneral
		}
	}
}

extension Address {
	var cachingIdentifier: CacheClient.Entry.OnLedgerEntity {
		.address(self)
	}
}

extension OnLedgerEntity.OnLedgerAccount.PoolUnitResources {
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
