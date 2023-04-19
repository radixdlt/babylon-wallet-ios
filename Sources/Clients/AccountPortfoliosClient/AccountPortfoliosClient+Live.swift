import CacheClient
import ClientPrelude
import GatewayAPI
import SharedModels

// MARK: - AccountPortfoliosClient + DependencyKey
extension AccountPortfoliosClient: DependencyKey {
	actor State {
		let portfolios: AsyncCurrentValueSubject<[AccountAddress: AccountPortfolio]> = .init([:])

		func setAccountPortfolio(_ portfolio: AccountPortfolio) {
			portfolios.value.updateValue(portfolio, forKey: portfolio.owner)
		}

		func portfolioForAccount(_ address: AccountAddress) -> AnyAsyncSequence<AccountPortfolio> {
			portfolios.compactMap { $0[address] }.eraseToAnyAsyncSequence()
		}
	}

	public static let liveValue: AccountPortfoliosClient = {
		let state = State()

		@Dependency(\.cacheClient) var cacheClient

		return AccountPortfoliosClient(
			fetchAccountPortfolio: { address, refresh in
				let portfolio = try await cacheClient.withCaching(
					cacheEntry: .accountPortfolio(.single(address.address)),
					forceRefresh: refresh,
					request: { try await fetchAccountPortfolio(address) }
				)

				await state.setAccountPortfolio(portfolio)

				return portfolio
			},
			portfolioForAccount: { address in
				await state.portfolioForAccount(address)
			}
		)
	}()
}

extension AccountPortfoliosClient {
	static func fetchAccountPortfolio(_ accountAddress: AccountAddress) async throws -> AccountPortfolio {
		async let fetchFungibleResources = fetchAccountFungibleResources(accountAddress)
		async let fetchNonFungibleResources = fetchAccountNonFungibleResources(accountAddress)

		let (fungibleResources, nonFungibleResources) = try await (fetchFungibleResources, fetchNonFungibleResources)

		return AccountPortfolio(
			owner: accountAddress,
			fungibleResources: fungibleResources,
			nonFungibleResources: nonFungibleResources
		)
	}
}

extension AccountPortfoliosClient {
	static func fetchAccountFungibleResources(_ accountAddress: AccountAddress) async throws -> AccountPortfolio.FungibleResources {
		let allResources = try await fetchAllPaginatedItems(fetchAccountFungibleResourcePage(accountAddress)).compactMap(\.global)
		let allDetails = try await loadResourceDetails(allResources.map(\.resourceAddress))

		return try allDetails.map { item in
			let amount = allResources.first { $0.resourceAddress == item.address }?.amount ?? "0"
			return try AccountPortfolio.FungibleResource(
				resourceAddress: .init(address: item.address),
				amount: .init(fromString: amount),
				divisibility: item.details?.fungible?.divisibility,
				name: item.metadata.name,
				symbol: item.metadata.symbol,
				description: item.metadata.description
			)
		}
	}

	static func fetchAccountNonFungibleResources(_ accountAddress: AccountAddress) async throws -> AccountPortfolio.NonFungibleResources {
		let allResources = try await fetchAllPaginatedItems(fetchNonFungibleResourcePage(accountAddress)).compactMap(\.vault)
		let allDetails = try await loadResourceDetails(allResources.map(\.resourceAddress))

		return try await allResources.map(\.resourceAddress)
			.parallelMap { resourceAddress in
				try await createAccountNonFungibleResource(
					accountAddress,
					resourceAddress: resourceAddress,
					metadata: allDetails.first(where: { $0.address == resourceAddress })?.metadata
				)
			}
	}

	static func createAccountNonFungibleResource(
		_ accountAddress: AccountAddress,
		resourceAddress: String,
		metadata: GatewayAPI.EntityMetadataCollection?
	) async throws -> AccountPortfolio.NonFungibleResource {
		let vaults = try await fetchAllPaginatedItems(fetchEntityNonFungibleResourceVaultPage(accountAddress, resourceAddress: resourceAddress))
		let ids = try await vaults.map(\.vaultAddress)
			.parallelMap { vaultAddress in
				try await fetchAllPaginatedItems(fetchEntityNonFungibleResourceIdsPage(
					accountAddress,
					resourceAddress: resourceAddress,
					vaultAddress: vaultAddress
				))
			}
			.flatMap { $0 }
			.map(\.nonFungibleId)

		return .init(
			resourceAddress: .init(address: resourceAddress),
			name: metadata?.name,
			description: metadata?.description,
			ids: ids
		)
	}
}

// MARK: - Pagination
extension AccountPortfoliosClient {
	struct PageCursor: Hashable, Sendable {
		let ledgerState: GatewayAPI.LedgerState
		let nextPagCursor: String
	}

	struct PaginatedResourceResponse<Resource: Sendable>: Sendable {
		let loadedItems: [Resource]
		let totalCount: Int64?
		let cursor: PageCursor?
	}

	@Sendable
	static func fetchAllPaginatedItems<Item>(
		_ paginatedRequest: @Sendable @escaping (_ cursor: PageCursor?) async throws -> PaginatedResourceResponse<Item>
	) async throws -> [Item] {
		func fetchAllPaginatedItems(
			collectedResources: PaginatedResourceResponse<Item>?
		) async throws -> [Item] {
			if let collectedResources, collectedResources.cursor == nil {
				return collectedResources.loadedItems
			}
			let response = try await paginatedRequest(collectedResources?.cursor)
			let oldItems = collectedResources?.loadedItems ?? []
			let allItems = oldItems + response.loadedItems
			let nextPageCursor: PageCursor? = {
				if response.loadedItems.isEmpty || allItems.count == response.totalCount.map(Int.init) {
					return nil
				}

				return response.cursor
			}()

			let result = PaginatedResourceResponse(loadedItems: allItems, totalCount: response.totalCount, cursor: nextPageCursor)
			return try await fetchAllPaginatedItems(collectedResources: result)
		}

		return try await fetchAllPaginatedItems(collectedResources: nil)
	}
}

// MARK: - Endpoints
extension AccountPortfoliosClient {
	@Sendable
	static func fetchAccountFungibleResourcePage(
		_ accountAddress: AccountAddress
	) -> (PageCursor?) async throws -> PaginatedResourceResponse<GatewayAPI.FungibleResourcesCollectionItem> {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		return { pageCursor in
			let request = GatewayAPI.StateEntityFungiblesPageRequest(
				atLedgerState: pageCursor?.ledgerState.selector,
				cursor: pageCursor?.nextPagCursor,
				limitPerPage: 20,
				address: accountAddress.address,
				aggregationLevel: .global
			)
			let response = try await gatewayAPIClient.getEntityFungibleTokensPage(request)

			return .init(
				loadedItems: response.items,
				totalCount: response.totalCount,
				cursor: response.nextCursor.map { PageCursor(ledgerState: response.ledgerState, nextPagCursor: $0) }
			)
		}
	}

	@Sendable
	static func fetchAccountFungibleResourceVaultsPage(
		_ accountAddress: AccountAddress,
		resourceAddress: String
	) -> (PageCursor?) async throws -> PaginatedResourceResponse<GatewayAPI.FungibleResourcesCollectionItemVaultAggregatedVaultItem> {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		return { pageCursor in
			let request = GatewayAPI.StateEntityFungibleResourceVaultsPageRequest(
				atLedgerState: pageCursor?.ledgerState.selector,
				cursor: pageCursor?.nextPagCursor,
				limitPerPage: 20,
				address: accountAddress.address,
				resourceAddress: resourceAddress
			)

			let response = try await gatewayAPIClient.getEntityFungibleResourceVaultPage(request)

			return .init(
				loadedItems: response.items,
				totalCount: response.totalCount,
				cursor: response.nextCursor.map { PageCursor(ledgerState: response.ledgerState, nextPagCursor: $0) }
			)
		}
	}

	@Sendable
	static func fetchNonFungibleResourcePage(
		_ accountAddress: AccountAddress
	) -> (PageCursor?) async throws -> PaginatedResourceResponse<GatewayAPI.NonFungibleResourcesCollectionItem> {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		return { pageCursor in
			let request = GatewayAPI.StateEntityNonFungiblesPageRequest(
				atLedgerState: pageCursor?.ledgerState.selector,
				cursor: pageCursor?.nextPagCursor,
				limitPerPage: 20,
				address: accountAddress.address,
				aggregationLevel: .vault
			)
			let response = try await gatewayAPIClient.getEntityNonFungibleTokensPage(request)

			return .init(
				loadedItems: response.items,
				totalCount: response.totalCount,
				cursor: response.nextCursor.map { PageCursor(ledgerState: response.ledgerState, nextPagCursor: $0) }
			)
		}
	}

	@Sendable
	static func fetchEntityNonFungibleResourceVaultPage(
		_ accountAddress: AccountAddress,
		resourceAddress: String
	) -> (PageCursor?) async throws -> PaginatedResourceResponse<GatewayAPI.NonFungibleResourcesCollectionItemVaultAggregatedVaultItem> {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		return { pageCursor in
			let request = GatewayAPI.StateEntityNonFungibleResourceVaultsPageRequest(
				atLedgerState: pageCursor?.ledgerState.selector,
				cursor: pageCursor?.nextPagCursor,
				address: accountAddress.address,
				resourceAddress: resourceAddress
			)
			let response = try await gatewayAPIClient.getEntityNonFungibleResourceVaultPage(request)

			return .init(
				loadedItems: response.items,
				totalCount: response.totalCount,
				cursor: response.nextCursor.map { PageCursor(ledgerState: response.ledgerState, nextPagCursor: $0) }
			)
		}
	}

	static func fetchEntityNonFungibleResourceIdsPage(
		_ accountAddress: AccountAddress,
		resourceAddress: String,
		vaultAddress: String
	) -> (PageCursor?) async throws -> PaginatedResourceResponse<GatewayAPI.NonFungibleIdsCollectionItem> {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		return { pageCursor in
			let request = GatewayAPI.StateEntityNonFungibleIdsPageRequest(
				atLedgerState: pageCursor?.ledgerState.selector,
				cursor: pageCursor?.nextPagCursor,
				address: accountAddress.address,
				vaultAddress: vaultAddress,
				resourceAddress: resourceAddress
			)
			let response = try await gatewayAPIClient.getAccountNonFungibleIdsPageRequest(request)

			return .init(
				loadedItems: response.items,
				totalCount: response.totalCount,
				cursor: response.nextCursor.map { PageCursor(ledgerState: response.ledgerState, nextPagCursor: $0) }
			)
		}
	}

	struct EmptyDetailsResponses: Error {}

	static let entityDetailsPageSize = 20
	@Sendable
	static func loadResourceDetails(_ addresses: [String]) async throws -> [GatewayAPI.StateEntityDetailsResponseItem] {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		return try await addresses
			.chunks(ofCount: entityDetailsPageSize)
			.map(Array.init)
			.parallelMap(gatewayAPIClient.getEntityDetails)
			.flatMap(\.items)
	}
}

// MARK: - AccountPortfoliosClient + TestDependencyKey
extension AccountPortfoliosClient: TestDependencyKey {
	public static let previewValue = AccountPortfoliosClient.noop

	public static let testValue = AccountPortfoliosClient(
		fetchAccountPortfolio: unimplemented("\(AccountPortfoliosClient.self).fetchAccountPortfolio"),
		portfolioForAccount: unimplemented("\(AccountPortfoliosClient.self).portfolioForAccount")
	)

	public static let noop = AccountPortfoliosClient(
		fetchAccountPortfolio: { _, _ in throw NoopError() },
		portfolioForAccount: { _ in fatalError() }
	)
}

extension GatewayAPI.LedgerState {
	var selector: GatewayAPI.LedgerStateSelector {
		// TODO: Determine what other fields should be sent
		.init(stateVersion: stateVersion)
	}
}

// MARK: - GatewayAPI.StateEntityDetailsResponse + Sendable
extension GatewayAPI.StateEntityDetailsResponse: @unchecked Sendable {}

// TODO: Move to shared utils
extension Array where Element: Sendable {
	func parallelMap<T: Sendable>(_ map: @Sendable @escaping (Element) async throws -> T) async throws -> [T] {
		try await withThrowingTaskGroup(of: T.self) { group in
			for element in self {
				_ = group.addTaskUnlessCancelled {
					try await map(element)
				}
			}
			return try await group.collect()
		}
	}
}

// TODO: Move to GatewayAPI
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
