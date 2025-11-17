
extension GatewayAPIClient {
	@Sendable
	func fetchEntityMetadata(_ address: String, ledgerState: GatewayAPI.LedgerState, nextCursor: String) async throws -> [GatewayAPI.EntityMetadataItem] {
		try await fetchAllPaginatedItems(
			cursor: .init(ledgerState: ledgerState, nextPageCursor: nextCursor),
			fetchEntityMetadataPage(address)
		)
	}

	@Sendable
	func fetchAllFungibleResources(
		_ entityDetails: GatewayAPI.StateEntityDetailsResponseItem,
		ledgerState: GatewayAPI.LedgerState
	) async throws -> [GatewayAPI.FungibleResourcesCollectionItem] {
		guard let firstPage = entityDetails.fungibleResources else {
			return [GatewayAPI.FungibleResourcesCollectionItem]()
		}

		guard let nextPageCursor = firstPage.nextCursor else {
			return firstPage.items
		}

		let additionalItems = try await fetchAllPaginatedItems(
			cursor: PageCursor(ledgerState: ledgerState, nextPageCursor: nextPageCursor),
			fetchFungibleResourcePage(entityDetails.address)
		)

		return firstPage.items + additionalItems
	}

	// FIXME: Similar function to the above, maybe worth extracting in a single function?
	@Sendable
	func fetchAllNonFungibleResources(
		_ entityDetails: GatewayAPI.StateEntityDetailsResponseItem,
		ledgerState: GatewayAPI.LedgerState
	) async throws -> [GatewayAPI.NonFungibleResourcesCollectionItem] {
		guard let firstPage = entityDetails.nonFungibleResources else {
			return [GatewayAPI.NonFungibleResourcesCollectionItem]()
		}

		guard let nextPageCursor = firstPage.nextCursor else {
			return firstPage.items
		}

		let additionalItems = try await fetchAllPaginatedItems(
			cursor: PageCursor(ledgerState: ledgerState, nextPageCursor: nextPageCursor),
			fetchNonFungibleResourcePage(entityDetails.address)
		)

		return firstPage.items + additionalItems
	}

	func fetchFungibleResourcePage(
		_ entityAddress: String
	) -> @Sendable (PageCursor?) async throws -> PaginatedResourceResponse<GatewayAPI.FungibleResourcesCollectionItem> {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		return { pageCursor in
			let request = GatewayAPI.StateEntityFungiblesPageRequest(
				atLedgerState: pageCursor?.ledgerState.selector,
				cursor: pageCursor?.nextPageCursor,
				address: entityAddress,
				aggregationLevel: .vault,
				optIns: .init(explicitMetadata: Array(Set<EntityMetadataKey>.resourceMetadataKeys.map(\.rawValue)))
			)
			let response = try await gatewayAPIClient.getEntityFungiblesPage(request)

			return .init(
				loadedItems: response.items,
				totalCount: response.totalCount,
				cursor: response.nextCursor.map {
					PageCursor(ledgerState: response.ledgerState, nextPageCursor: $0)
				}
			)
		}
	}

	func getAccountLockerVaultsPage(lockerAddress: LockerAddress, accountAddress: AccountAddress) -> @Sendable (PageCursor?) async throws -> PaginatedResourceResponse<GatewayAPI.AccountLockerVaultCollectionItem> {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		return { pageCursor in
			let request = GatewayAPI.StateAccountLockerPageVaultsRequest(
				atLedgerState: pageCursor?.ledgerState.selector,
				cursor: pageCursor?.nextPageCursor,
				lockerAddress: lockerAddress.address,
				accountAddress: accountAddress.address
			)
			let response = try await gatewayAPIClient.getAccountLockerVaults(request)

			return .init(
				loadedItems: response.items,
				totalCount: response.totalCount,
				cursor: response.nextCursor.map {
					PageCursor(ledgerState: response.ledgerState, nextPageCursor: $0)
				}
			)
		}
	}

	func fetchEntityMetadataPage(
		_ address: String
	) -> @Sendable (PageCursor?) async throws -> PaginatedResourceResponse<GatewayAPI.EntityMetadataItem> {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		return { pageCursor in
			let request = GatewayAPI.StateEntityMetadataPageRequest(
				atLedgerState: pageCursor?.ledgerState.selector,
				cursor: pageCursor?.nextPageCursor,
				address: address
			)
			let response = try await gatewayAPIClient.getEntityMetadataPage(request)

			return .init(
				loadedItems: response.items,
				totalCount: response.totalCount,
				cursor: response.nextCursor.map {
					PageCursor(ledgerState: response.ledgerState, nextPageCursor: $0)
				}
			)
		}
	}

	func fetchNonFungibleResourcePage(
		_ accountAddress: String
	) -> @Sendable (PageCursor?) async throws -> PaginatedResourceResponse<GatewayAPI.NonFungibleResourcesCollectionItem> {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		return { pageCursor in
			let request = GatewayAPI.StateEntityNonFungiblesPageRequest(
				atLedgerState: pageCursor?.ledgerState.selector,
				cursor: pageCursor?.nextPageCursor,
				address: accountAddress,
				aggregationLevel: .vault,
				optIns: .init(
					nonFungibleIncludeNfids: false,
					explicitMetadata: .init(Array(Set<EntityMetadataKey>.resourceMetadataKeys.map(\.rawValue)))
				)
			)
			let response = try await gatewayAPIClient.getEntityNonFungiblesPage(request)

			return .init(
				loadedItems: response.items,
				totalCount: response.totalCount,
				cursor: response.nextCursor.map {
					PageCursor(ledgerState: response.ledgerState, nextPageCursor: $0)
				}
			)
		}
	}
}

// MARK: - Pagination
extension GatewayAPIClient {
	/// A page cursor is required to have the `nextPageCurosr` itself, as well the `ledgerState` of the previous page.
	struct PageCursor: Hashable, Sendable {
		let ledgerState: GatewayAPI.LedgerState
		let nextPageCursor: String

		init(ledgerState: GatewayAPI.LedgerState, nextPageCursor: String) {
			self.ledgerState = ledgerState
			self.nextPageCursor = nextPageCursor
		}
	}

	struct PaginatedResourceResponse<Resource: Sendable>: Sendable {
		let loadedItems: [Resource]
		let totalCount: Int64?
		let cursor: PageCursor?

		init(loadedItems: [Resource], totalCount: Int64?, cursor: PageCursor?) {
			self.loadedItems = loadedItems
			self.totalCount = totalCount
			self.cursor = cursor
		}
	}

	/// Recursively fetches all of the pages for a given paginated request.
	///
	/// Provide an initial page cursor if needed to load the all the items starting with a given page
	@Sendable
	func fetchAllPaginatedItems<Item>(
		cursor: PageCursor?,
		_ paginatedRequest: @Sendable @escaping (_ cursor: PageCursor?) async throws -> PaginatedResourceResponse<Item>
	) async throws -> [Item] {
		@Sendable
		func fetchAllPaginatedItems(
			collectedResources: PaginatedResourceResponse<Item>?
		) async throws -> [Item] {
			/// Finish when some items where loaded and the nextPageCursor is nil.
			if let collectedResources, collectedResources.cursor == nil {
				return collectedResources.loadedItems
			}

			/// We can request here with nil nextPageCursor, as the first page will not have a cursor.
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
