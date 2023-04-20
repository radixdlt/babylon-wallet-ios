import CacheClient
import ClientPrelude
import GatewayAPI
import SharedModels

// MARK: - AccountPortfoliosClient + DependencyKey
extension AccountPortfoliosClient: DependencyKey {
	/// Internal state that holds all o the loaded portfolios.
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

		@Sendable
		func fetchAccountPortfolio(_ accountAddress: AccountAddress, refresh: Bool) async throws -> AccountPortfolio {
			let portfolio = try await cacheClient.withCaching(
				cacheEntry: .accountPortfolio(.single(accountAddress.address)),
				forceRefresh: refresh,
				request: { try await AccountPortfoliosClient.fetchAccountPortfolio(accountAddress) }
			)

			await state.setAccountPortfolio(portfolio)

			return portfolio
		}

		return AccountPortfoliosClient(
			fetchAccountPortfolios: { addresses, refresh in
				try await addresses.parallelMap {
					try await fetchAccountPortfolio($0, refresh: refresh)
				}
			},
			fetchAccountPortfolio: fetchAccountPortfolio,
			portfolioForAccount: { address in
				await state.portfolioForAccount(address)
			}
		)
	}()
}

extension AccountPortfoliosClient {
	@Sendable
	static func fetchAccountPortfolio(
		_ accountAddress: AccountAddress
	) async throws -> AccountPortfolio {
		async let fetchFungibleResources = fetchAccountFungibleResources(accountAddress)
		async let fetchNonFungibleResources = fetchAccountNonFungibleResources(accountAddress)

		let (fungibleResources, nonFungibleResources) = try await (fetchFungibleResources, fetchNonFungibleResources)

		return AccountPortfolio(
			owner: accountAddress,
			fungibleResources: fungibleResources,
			nonFungibleResources: nonFungibleResources
		)
	}

	@Sendable
	static func fetchAccountFungibleResources(
		_ accountAddress: AccountAddress
	) async throws -> AccountPortfolio.FungibleResources {
		// Fetch all fungible resources associated with the account.
		let allResources = try await fetchAllPaginatedItems(fetchAccountFungibleResourcePage(accountAddress)).compactMap(\.global)

		// Fetch all the detailed information for the loaded resources.
		let allDetails = try await fetchResourceDetails(allResources.map(\.resourceAddress))

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

	@Sendable
	static func fetchAccountNonFungibleResources(
		_ accountAddress: AccountAddress
	) async throws -> AccountPortfolio.NonFungibleResources {
		// Fetch all fungible resources associated with the account.
		// The non fungible resources are loaded with vault aggregation level. The global aggregation is not appropriate to be used
		// due to how non_fungible_id's have to be retrieved
		let allResources = try await fetchAllPaginatedItems(fetchNonFungibleResourcePage(accountAddress)).compactMap(\.vault)

		// Fetch all the detailed information for the loaded resources.
		let allDetails = try await fetchResourceDetails(allResources.map(\.resourceAddress))

		return try await allResources
			.map(\.resourceAddress)
			.parallelMap { resourceAddress in
				try await createAccountNonFungibleResource(
					accountAddress,
					resourceAddress: resourceAddress,
					metadata: allDetails.first(where: { $0.address == resourceAddress })?.metadata
				)
			}
	}

	@Sendable
	static func createAccountNonFungibleResource(
		_ accountAddress: AccountAddress,
		resourceAddress: String,
		metadata: GatewayAPI.EntityMetadataCollection?
	) async throws -> AccountPortfolio.NonFungibleResource {
		// Fetch all the vaults associated with the given non fungible resources.
		// In most cases, if not always, it should be just one vault, but due to how the API is designed better be sure to fetch all of them.
		let vaults = try await fetchAllPaginatedItems(fetchEntityNonFungibleResourceVaultPage(accountAddress, resourceAddress: resourceAddress))

		// Fetch all the ids owned by the account.
		// Requires basically to iterate over all the vaults to get the ids.
		let ids = try await vaults
			.map(\.vaultAddress)
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

	/// Recursively fetches all of the pages for a given paginated request.
	@Sendable
	static func fetchAllPaginatedItems<Item>(
		_ paginatedRequest: @Sendable @escaping (_ cursor: PageCursor?) async throws -> PaginatedResourceResponse<Item>
	) async throws -> [Item] {
		@Sendable
		func fetchAllPaginatedItems(
			collectedResources: PaginatedResourceResponse<Item>?
		) async throws -> [Item] {
			/// Finish when no next page cursor is available
			if let collectedResources, collectedResources.cursor == nil {
				return collectedResources.loadedItems
			}
			let response = try await paginatedRequest(collectedResources?.cursor)
			let oldItems = collectedResources?.loadedItems ?? []
			let allItems = oldItems + response.loadedItems

			let nextPageCursor: PageCursor? = {
				// Safeguard: Don't rely only on the gateway returning nil for the next page cursor,
				// if happened to load an empty page, or all items were loaded - next page cursor is nil.
				if response.loadedItems.isEmpty || allItems.count == response.totalCount.map(Int.init) {
					return nil
				}

				//
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
	static func fetchAccountFungibleResourcePage(
		_ accountAddress: AccountAddress
	) -> @Sendable (PageCursor?) async throws -> PaginatedResourceResponse<GatewayAPI.FungibleResourcesCollectionItem> {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		return { pageCursor in
			let request = GatewayAPI.StateEntityFungiblesPageRequest(
				atLedgerState: pageCursor?.ledgerState.selector,
				cursor: pageCursor?.nextPagCursor,
				address: accountAddress.address,
				aggregationLevel: .global
			)
			let response = try await gatewayAPIClient.getEntityFungiblesPage(request)

			return .init(
				loadedItems: response.items,
				totalCount: response.totalCount,
				cursor: response.nextCursor.map { PageCursor(ledgerState: response.ledgerState, nextPagCursor: $0) }
			)
		}
	}

	static func fetchAccountFungibleResourceVaultsPage(
		_ accountAddress: AccountAddress,
		resourceAddress: String
	) -> (PageCursor?) async throws -> PaginatedResourceResponse<GatewayAPI.FungibleResourcesCollectionItemVaultAggregatedVaultItem> {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		return { pageCursor in
			let request = GatewayAPI.StateEntityFungibleResourceVaultsPageRequest(
				atLedgerState: pageCursor?.ledgerState.selector,
				cursor: pageCursor?.nextPagCursor,
				address: accountAddress.address,
				resourceAddress: resourceAddress
			)

			let response = try await gatewayAPIClient.getEntityFungibleResourceVaultsPage(request)

			return .init(
				loadedItems: response.items,
				totalCount: response.totalCount,
				cursor: response.nextCursor.map { PageCursor(ledgerState: response.ledgerState, nextPagCursor: $0) }
			)
		}
	}

	static func fetchNonFungibleResourcePage(
		_ accountAddress: AccountAddress
	) -> @Sendable (PageCursor?) async throws -> PaginatedResourceResponse<GatewayAPI.NonFungibleResourcesCollectionItem> {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		return { pageCursor in
			let request = GatewayAPI.StateEntityNonFungiblesPageRequest(
				atLedgerState: pageCursor?.ledgerState.selector,
				cursor: pageCursor?.nextPagCursor,
				address: accountAddress.address,
				aggregationLevel: .vault
			)
			let response = try await gatewayAPIClient.getEntityNonFungiblesPage(request)

			return .init(
				loadedItems: response.items,
				totalCount: response.totalCount,
				cursor: response.nextCursor.map { PageCursor(ledgerState: response.ledgerState, nextPagCursor: $0) }
			)
		}
	}

	static func fetchEntityNonFungibleResourceVaultPage(
		_ accountAddress: AccountAddress,
		resourceAddress: String
	) -> @Sendable (PageCursor?) async throws -> PaginatedResourceResponse<GatewayAPI.NonFungibleResourcesCollectionItemVaultAggregatedVaultItem> {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		return { pageCursor in
			let request = GatewayAPI.StateEntityNonFungibleResourceVaultsPageRequest(
				atLedgerState: pageCursor?.ledgerState.selector,
				cursor: pageCursor?.nextPagCursor,
				address: accountAddress.address,
				resourceAddress: resourceAddress
			)
			let response = try await gatewayAPIClient.getEntityNonFungibleResourceVaultsPage(request)

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
	) -> @Sendable (PageCursor?) async throws -> PaginatedResourceResponse<GatewayAPI.NonFungibleIdsCollectionItem> {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		return { pageCursor in
			let request = GatewayAPI.StateEntityNonFungibleIdsPageRequest(
				atLedgerState: pageCursor?.ledgerState.selector,
				cursor: pageCursor?.nextPagCursor,
				address: accountAddress.address,
				vaultAddress: vaultAddress,
				resourceAddress: resourceAddress
			)
			let response = try await gatewayAPIClient.getEntityNonFungibleIdsPage(request)

			return .init(
				loadedItems: response.items,
				totalCount: response.totalCount,
				cursor: response.nextCursor.map { PageCursor(ledgerState: response.ledgerState, nextPagCursor: $0) }
			)
		}
	}
}

// MARK: - Resource details endpoint
extension AccountPortfoliosClient {
	static let entityDetailsPageSize = 20
	@Sendable
	static func fetchResourceDetails(_ addresses: [String]) async throws -> [GatewayAPI.StateEntityDetailsResponseItem] {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		return try await addresses
			.chunks(ofCount: entityDetailsPageSize)
			.map(Array.init)
			.parallelMap(gatewayAPIClient.getEntityDetails)
			.flatMap(\.items)
	}
}
