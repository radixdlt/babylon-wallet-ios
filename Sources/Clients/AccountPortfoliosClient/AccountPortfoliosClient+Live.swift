import CacheClient
import ClientPrelude
import EngineToolkitClient
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

		func setAccountPortfolios(_ portfolio: [AccountPortfolio]) {
			portfolios.value = portfolio.reduce(into: [AccountAddress: AccountPortfolio]()) { partialResult, portfolio in
				partialResult[portfolio.owner] = portfolio
			}
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
			fetchAccountPortfolios: { accountAddresses, refresh in
				let portfolios = try await cacheClient.withCaching(
					cacheEntry: .accountPortfolio(.all),
					forceRefresh: refresh,
					request: { try await AccountPortfoliosClient.fetchAccountPortfolios(accountAddresses) }
				)
				await state.setAccountPortfolios(portfolios)
				return portfolios
			},
			fetchAccountPortfolio: { accountAddress, refresh in
				let portfolio = try await cacheClient.withCaching(
					cacheEntry: .accountPortfolio(.single(accountAddress.address)),
					forceRefresh: refresh,
					request: { try await AccountPortfoliosClient.fetchAccountPortfolio(accountAddress) }
				)

				await state.setAccountPortfolio(portfolio)

				return portfolio
			},
			portfolioForAccount: { address in
				await state.portfolioForAccount(address)
			},
			portfolios: { state.portfolios.value.map(\.value) }
		)
	}()
}

extension AccountPortfoliosClient {
	@Sendable
	static func fetchAccountPortfolios(
		_ addresses: [AccountAddress]
	) async throws -> [AccountPortfolio] {
		let details = try await fetchResourceDetails(addresses.map(\.address))
		return try await details.items.parallelMap {
			try await createAccountPortfolio($0, ledgerState: details.ledgerState)
		}
	}

	@Sendable
	static func fetchAccountPortfolio(
		_ accountAddress: AccountAddress
	) async throws -> AccountPortfolio {
		let accountDetails = try await fetchResourceDetails([accountAddress.address])
		return try await createAccountPortfolio(accountDetails.items.first!, ledgerState: accountDetails.ledgerState)
	}
}

extension AccountPortfoliosClient {
	@Sendable
	static func createAccountPortfolio(
		_ rawAccountDetails: GatewayAPI.StateEntityDetailsResponseItem,
		ledgerState: GatewayAPI.LedgerState
	) async throws -> AccountPortfolio {
		async let fetchAllFungibleResources = {
			guard let firstPage = rawAccountDetails.fungibleResources else {
				return [GatewayAPI.FungibleResourcesCollectionItem]()
			}

			guard let nextPageCursor = firstPage.nextCursor else {
				return firstPage.items
			}

			let additionalItems = try await fetchAllPaginatedItems(
				cursor: PageCursor(ledgerState: ledgerState, nextPagCursor: nextPageCursor),
				fetchAccountFungibleResourcePage(rawAccountDetails.address)
			)

			return firstPage.items + additionalItems
		}

		async let fetchAllNonFungibleResources = {
			guard let firstPage = rawAccountDetails.nonFungibleResources else {
				return [GatewayAPI.NonFungibleResourcesCollectionItem]()
			}

			guard let nextPageCursor = firstPage.nextCursor else {
				return firstPage.items
			}

			let additionalItems = try await fetchAllPaginatedItems(
				cursor: PageCursor(ledgerState: ledgerState, nextPagCursor: nextPageCursor),
				fetchNonFungibleResourcePage(rawAccountDetails.address)
			)

			return firstPage.items + additionalItems
		}

		let (rawFungibleResources, rawNonFungibleResources) = try await (fetchAllFungibleResources(), fetchAllNonFungibleResources())

		async let fungibleResources = createFungibleResources(rawItems: rawFungibleResources)
		async let nonFungibleResources = createNonFungibleResources(rawAccountDetails.address, rawItems: rawNonFungibleResources)

		return try AccountPortfolio(
			owner: .init(address: rawAccountDetails.address),
			fungibleResources: try await fungibleResources,
			nonFungibleResources: try await nonFungibleResources
		)
	}

	@Sendable
	static func createFungibleResources(
		rawItems: [GatewayAPI.FungibleResourcesCollectionItem]
	) async throws -> AccountPortfolio.FungibleResources {
		@Dependency(\.engineToolkitClient) var engineToolkitClient

		let rawItems = rawItems.compactMap(\.vault)
		guard !rawItems.isEmpty else {
			return .init()
		}

		// Fetch all the detailed information for the loaded resources.
		// TODO: This will become obsolete with next version of GW, the details would be embeded in FungibleResourcesCollection
		let allResourceDetails = try await fetchResourceDetails(rawItems.map(\.resourceAddress)).items

		var xrdResource: AccountPortfolio.FungibleResource?
		var nonXrdResources: [AccountPortfolio.FungibleResource] = []

		for resource in rawItems {
			let amount: BigDecimal = {
				guard let resourceVault = resource.vaults.items.first else {
					loggerGlobal.warning("Account Portfolio: \(resource.resourceAddress) does not have any vaults")
					return .zero
				}

				do {
					return try BigDecimal(fromString: resourceVault.amount)
				} catch {
					loggerGlobal.error(
						"Account Portfolio: Failed to parse amount for resource: \(resource.resourceAddress), reason: \(error.localizedDescription)"
					)
					return .zero
				}
			}()

			let resourceAddress = ResourceAddress(address: resource.resourceAddress)
			let isXRD = try engineToolkitClient.isXRD(resource: resourceAddress, on: Radix.Network.default.id)
			let resourceDetails = allResourceDetails.first { $0.address == resource.resourceAddress }
			let metadata = resourceDetails?.metadata

			let resource = AccountPortfolio.FungibleResource(
				resourceAddress: resourceAddress,
				amount: amount,
				divisibility: resourceDetails?.details?.fungible?.divisibility,
				name: metadata?.name,
				symbol: metadata?.symbol,
				description: metadata?.description
			)

			if isXRD {
				xrdResource = resource
			} else {
				nonXrdResources.append(resource)
			}
		}

		return .init(
			xrdResource: xrdResource,
			nonXrdResources: nonXrdResources
		)
	}

	@Sendable
	static func createNonFungibleResources(
		_ accountAddress: String,
		rawItems: [GatewayAPI.NonFungibleResourcesCollectionItem]
	) async throws -> AccountPortfolio.NonFungibleResources {
		let rawItems = rawItems.compactMap(\.vault)

		guard !rawItems.isEmpty else {
			return []
		}

		// TODO: This will become obsolete with next version of GW, the details would be embeded in FungibleResourcesCollection
		let allResourceDetails = try await fetchResourceDetails(rawItems.map(\.resourceAddress)).items

		return try await rawItems.parallelMap { resource in
			let vault = resource.vaults.items.first
			let nftIds: [String] = try await {
				guard let vault = resource.vaults.items.first else {
					return []
				}

				return try await fetchAllPaginatedItems(
					cursor: nil,
					fetchEntityNonFungibleResourceIdsPage(
						accountAddress,
						resourceAddress: resource.resourceAddress,
						vaultAddress: vault.vaultAddress
					)
				)
				.map(\.nonFungibleId)
			}()

			let details = allResourceDetails.first { $0.address == resource.resourceAddress }

			return AccountPortfolio.NonFungibleResource(
				resourceAddress: .init(address: resource.resourceAddress),
				name: details?.metadata.name,
				description: details?.metadata.description,
				ids: nftIds
			)
		}
	}
}

// MARK: - Endpoints
extension AccountPortfoliosClient {
	static func fetchAccountFungibleResourcePage(
		_ accountAddress: String
	) -> @Sendable (PageCursor?) async throws -> PaginatedResourceResponse<GatewayAPI.FungibleResourcesCollectionItem> {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		return { pageCursor in
			let request = GatewayAPI.StateEntityFungiblesPageRequest(
				atLedgerState: pageCursor?.ledgerState.selector,
				cursor: pageCursor?.nextPagCursor,
				address: accountAddress,
				aggregationLevel: .global
			)
			let response = try await gatewayAPIClient.getEntityFungiblesPage(request)

			return .init(
				loadedItems: response.items,
				totalCount: response.totalCount,
				cursor: response.nextCursor.map {
					PageCursor(ledgerState: response.ledgerState, nextPagCursor: $0)
				}
			)
		}
	}

	static func fetchNonFungibleResourcePage(
		_ accountAddress: String
	) -> @Sendable (PageCursor?) async throws -> PaginatedResourceResponse<GatewayAPI.NonFungibleResourcesCollectionItem> {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		return { pageCursor in
			let request = GatewayAPI.StateEntityNonFungiblesPageRequest(
				atLedgerState: pageCursor?.ledgerState.selector,
				cursor: pageCursor?.nextPagCursor,
				address: accountAddress,
				aggregationLevel: .vault
			)
			let response = try await gatewayAPIClient.getEntityNonFungiblesPage(request)

			return .init(
				loadedItems: response.items,
				totalCount: response.totalCount,
				cursor: response.nextCursor.map {
					PageCursor(ledgerState: response.ledgerState, nextPagCursor: $0)
				}
			)
		}
	}

	static func fetchEntityNonFungibleResourceIdsPage(
		_ accountAddress: String,
		resourceAddress: String,
		vaultAddress: String
	) -> @Sendable (PageCursor?) async throws -> PaginatedResourceResponse<GatewayAPI.NonFungibleIdsCollectionItem> {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		return { pageCursor in
			let request = GatewayAPI.StateEntityNonFungibleIdsPageRequest(
				atLedgerState: pageCursor?.ledgerState.selector,
				cursor: pageCursor?.nextPagCursor,
				address: accountAddress,
				vaultAddress: vaultAddress,
				resourceAddress: resourceAddress
			)
			let response = try await gatewayAPIClient.getEntityNonFungibleIdsPage(request)

			return .init(
				loadedItems: response.items,
				totalCount: response.totalCount,
				cursor: response.nextCursor.map {
					PageCursor(ledgerState: response.ledgerState, nextPagCursor: $0)
				}
			)
		}
	}
}

// MARK: - Resource details endpoint
extension AccountPortfoliosClient {
	static let entityDetailsPageSize = 20
	struct EmptyEntityDetailsResponse: Error {}

	@Sendable
	static func fetchResourceDetails(_ addresses: [String]) async throws -> GatewayAPI.StateEntityDetailsResponse {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		let allResponses = try await addresses
			.chunks(ofCount: entityDetailsPageSize)
			.map(Array.init)
			.parallelMap(gatewayAPIClient.getEntityDetails)
		guard !allResponses.isEmpty else {
			throw EmptyEntityDetailsResponse()
		}

		let allItems = allResponses.flatMap(\.items)
		let ledgerState = allResponses.first!.ledgerState

		return .init(ledgerState: ledgerState, items: allItems)
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
		cursor: PageCursor?,
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

				return response.cursor
			}()

			let result = PaginatedResourceResponse(loadedItems: allItems, totalCount: response.totalCount, cursor: nextPageCursor)
			return try await fetchAllPaginatedItems(collectedResources: result)
		}

		return try await fetchAllPaginatedItems(
			collectedResources: cursor.map {
				PaginatedResourceResponse(loadedItems: [], totalCount: nil, cursor: $0)
			}
		)
	}
}
