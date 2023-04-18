import CacheClient
import ClientPrelude
import GatewayAPI
import SharedModels

// MARK: - AccountPortfoliosClient + DependencyKey
extension AccountPortfoliosClient: DependencyKey {
        public static let liveValue: AccountPortfoliosClient = {
                let portfolios: AsyncCurrentValueSubject<Set<AccountPortfolio>> = .init([])

                // Internal state

                return AccountPortfoliosClient(
                        fetchAccountPortfolios: { accountAddresses in
                                let loadedPortfolios = try await fetchAccountPortfolios(accountAddresses)
                                portfolios.value = Set(loadedPortfolios)
                                return loadedPortfolios
                        },
                        fetchAccountPortfolio: { address, refresh in
                                let portfolio = try await fetchAccountPortfolio(address, refresh)
                                portfolios.value.update(with: portfolio)
                                return portfolio
                        },
//                        fetchMoreFungibleTokens: { accountAddress in
//                                resourcePageCursor.
//                                guard var portfolio = portfolios.value.first(where: { $0.owner == accountAddress }),
//                                      let nextPageCursor = portfolio.fungibleResources.nextPageCursor
//                                else {
//                                        fatalError()
//                                }
//
//                                let (tokens, pageCursor) = try await fetchMoreFungibleTokens(accountAddress, nextPageCursor: nextPageCursor)
//                                portfolio.fungibleResources.nextPageCursor = pageCursor
//                                portfolio.fungibleResources.loaded.append(contentsOf: tokens)
//                                portfolios.value.update(with: portfolio)
//                                return portfolio
//                        },
//                        fetchMoreNonFungibleTokens: { accounAddress in
//                                guard var portfolio = portfolios.value.first(where: { $0.owner == accounAddress }),
//                                      let nextPageCursor = portfolio.nonFungibleResources.nextPageCursor
//                                else {
//                                        fatalError()
//                                }
//
//                                let (tokens, pageCursor) = try await fetchMoreNonFungibleTokens(accounAddress, nextPageCursor: nextPageCursor)
//
//                                return portfolio
//                        },
                        portfolioForAccount: { address in
                                portfolios.compactMap { portfolios in
                                        portfolios.first { portfolio in
                                                portfolio.owner == address
                                        }
                                }
                                .share()
                                .eraseToAnyAsyncSequence()

                        },
                        portfolios: portfolios
                )
        }()
}

extension AccountPortfoliosClient {
        static func fetchAccountFungibleResources(_ accountAddress: AccountAddress) async throws -> AccountPortfolio.FungibleResources {
                let allResources = try await fetchAllPaginatedItems(fetchAccountFungibleResourcePage(accountAddress)).compactMap(\.global)

                le
                // fetch all details
                let details = try await loadResourceDetails(allResources.map(\.resourceAddress))

                details.map { item in
                        AccountPortfolio.FungibleResource(resourceAddress: .init(address: item.address),
                                                          amount: .init(fromString: item),
                                                          tokenDescription: item.metadata.description)
                }
        }
}

struct PageCursor: Hashable, Sendable {
        let ledgerState: GatewayAPI.LedgerState
        let nextPagCursor: String
}

struct PaginatedResource<Resource> {
        let loadedItems: [Resource]
        let cursor: PageCursor?
}

// MARK: - Pagination
extension AccountPortfoliosClient {
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
                                cursor: response.nextCursor.map {PageCursor(ledgerState: response.ledgerState, nextPagCursor: $0)})
                }
        }

        @Sendable
        static func fetchNonFungibleResourcePage(
                _ accountAddress: AccountAddress,
                pageCursor: PageCursor?
        ) async throws -> GatewayAPI.StateEntityNonFungiblesPageResponse {
                @Dependency(\.gatewayAPIClient) var gatewayAPIClient

                let request = GatewayAPI.StateEntityNonFungiblesPageRequest(
                        atLedgerState: pageCursor?.ledgerState.selector,
                        cursor: pageCursor?.nextPagCursor,
                        limitPerPage: 20,
                        address: accountAddress.address,
                        aggregationLevel: .vault
                )
                return try await gatewayAPIClient.getEntityNonFungibleTokensPage(request)
        }

        @Sendable
        static func loadEntityNonFungibleResourceVaultPage(
                _ accountAddress: AccountAddress,
                resourceAddress: String,
                pageCursor: PageCursor?
        ) async throws -> GatewayAPI.StateEntityNonFungibleResourceVaultsPageResponse {
                @Dependency(\.gatewayAPIClient) var gatewayAPIClient

                let request = GatewayAPI.StateEntityNonFungibleResourceVaultsPageRequest(
                        atLedgerState: pageCursor?.ledgerState.selector,
                        cursor: pageCursor?.nextPagCursor,
                        limitPerPage: 20,
                        address: accountAddress.address,
                        resourceAddress: resourceAddress
                )
                return try await gatewayAPIClient.getEntityNonFungibleResourceVaultPage(request)
        }

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
                fetchAccountPortfolios: unimplemented("\(AccountPortfoliosClient.self).fetchAccountPortfolios"),
                fetchAccountPortfolio: unimplemented("\(AccountPortfoliosClient.self).fetchAccountPortfolio"),
                fetchAccountNonFungibleResourceIds: unimplemented("\(AccountPortfoliosClient.self).fetchAccountNonFungibleResourceIds"),
//                fetchMoreFungibleTokens: unimplemented("\(AccountPortfoliosClient.self).fetchMoreFungibleTokens"),
//                fetchMoreNonFungibleTokens: unimplemented("\(AccountPortfoliosClient.self).fetchMoreNonFungibleTokens"),
                portfolioForAccount: unimplemented("\(AccountPortfoliosClient.self).portfolioForAccount"),
                portfolios: .init([])
        )

        public static let noop = AccountPortfoliosClient(
                fetchAccountPortfolios: { _ in throw NoopError() },
                fetchAccountPortfolio: { _, _ in throw NoopError() },
                fetchAccountNonFungibleResourceIds: {_,_ in throw NoopError() },
//                fetchMoreFungibleTokens: { _ in throw NoopError() },
//                fetchMoreNonFungibleTokens: { _ in throw NoopError() },
                portfolioForAccount: { _ in fatalError() },
                portfolios: .init([])
        )
}

//extension AccountPortfoliosClient {
//        static let fetchAccountPortfolios: FetchAccountPortfolios = { addresses in
//                @Dependency(\.gatewayAPIClient) var gatewayAPIClient
//                return try await loadResourceDetails(addresses.map(\.address))
//                        .parallelMap(createAccountPortfolio)
//        }
//}

//extension AccountPortfoliosClient {
//        @Sendable
//        static func fetchAccountPortfolio(_ accountAddress: AccountAddress) async throws -> State.AccountResources {
//                async let fetchFungibleResources = fetchAllFungibleResources(accountAddress)
//                fatalError()
//        }
//
//        static func fetchAllFungibleResources(
//                _ accountAddress: AccountAddress,
//                _ collectedResources: State.AccountResources.FungibleResources? = nil
//        ) async throws -> State.AccountResources.FungibleResources {
//                // TODO: How can  we be sure that we don't end in an infinite loop?
//                if let collectedResources, collectedResources.cursor == nil {
//                        return collectedResources
//                }
//
//                let cursor = collectedResources?.cursor
//                let response = try await fetchFungibleResourcePage(accountAddress, pageCursor: cursor)
//
//                let newItems = try await createFungibleResources(response.items)
//                let nextPageCursor: PageCursor? = {
//                        guard !newItems.isEmpty else {
//                                return nil
//                        }
//
//                        return response.nextCursor.map { PageCursor(ledgerState: response.ledgerState, nextPagCursor: $0) }
//                }()
//
//                let oldItems = collectedResources?.items ?? []
//
//                let resources = State.AccountResources.FungibleResources(cursor: nextPageCursor, totalCount: response.totalCount, items: oldItems + newItems)
//                return try await fetchAllFungibleResources(accountAddress, resources)
//        }
//
//        static func fetchFungibleResourcePage(_ accountAddress: AccountAddress, pageCursor: PageCursor?) async throws -> GatewayAPI.StateEntityFungiblesPageResponse {
//                @Dependency(\.gatewayAPIClient) var gatewayAPIClient
//
//                let request = GatewayAPI.StateEntityFungiblesPageRequest(
//                        atLedgerState: pageCursor?.ledgerState.selector,
//                        cursor: pageCursor?.nextPagCursor,
//                        limitPerPage: 20,
//                        address: accountAddress.address,
//                        aggregationLevel: .global
//                )
//                return try await gatewayAPIClient.getEntityFungibleTokensPage(request)
//        }
//}
//
//extension AccountPortfoliosClient {
//        static func fetchAllNonFungibleResources(
//                _ accountAddress: AccountAddress,
//                _ collectedResources: State.AccountResources.NonFungibleResources? = nil
//        ) async throws -> State.AccountResources.NonFungibleResources {
//                // TODO: How can  we be sure that we don't end in an infinite loop?
//                if let collectedResources, collectedResources.cursor == nil {
//                        return collectedResources
//                }
//
//                let cursor = collectedResources?.cursor
//                let response = try await fetchNonFungibleResourcePage(accountAddress, pageCursor: cursor)
//
//                let newItems = try await createNonFungibleResources(accountAddress, response.items)
//                let nextPageCursor: PageCursor? = {
//                        guard !newItems.isEmpty else {
//                                return nil
//                        }
//
//                        return response.nextCursor.map { PageCursor(ledgerState: response.ledgerState, nextPagCursor: $0) }
//                }()
//
//                let oldItems = collectedResources?.items ?? []
//
//                let resources = State.AccountResources.NonFungibleResources(cursor: nextPageCursor, totalCount: response.totalCount, items: oldItems + newItems)
//                return try await fetchAllFungibleResources(accountAddress, resources)
//        }
//
//        static func fetchNonFungibleResourcePage(_ accountAddress: AccountAddress, pageCursor: PageCursor?) async throws -> GatewayAPI.StateEntityNonFungiblesPageResponse {
//                @Dependency(\.gatewayAPIClient) var gatewayAPIClient
//
//                let request = GatewayAPI.StateEntityNonFungiblesPageRequest(
//                        atLedgerState: pageCursor?.ledgerState.selector,
//                        cursor: pageCursor?.nextPagCursor,
//                        limitPerPage: 20,
//                        address: accountAddress.address,
//                        aggregationLevel: .vault
//                )
//                let response = try await gatewayAPIClient.getEntityNonFungibleTokensPage(request)
//
//                let fungibleTokens = try await createNonFungibleTokens(response.items)
//                let nextPageCursor: PageCursor? = {
//                        guard !fungibleTokens.isEmpty else {
//                                return nil
//                        }
//
//                        return response.nextCursor.map { PageCursor(ledgerState: response.ledgerState, nextPagCursor: $0) }
//                }()
//                return (fungibleTokens, nextPageCursor)
//        }
//
//
//        @Sendable
//        static func createNonFungibleResources(_ accountAddress: AccountAddress, _ items: [GatewayAPI.NonFungibleResourcesCollectionItem]) async throws -> State.NonFungibleResource {
//                @Dependency(\.gatewayAPIClient) var gatewayAPIClient
//
//                let items = items.compactMap(\.vault)
//
//
//                // This will most probably go away - the GW should return the details in `FungibleResourcesCollectionItem`
//                let allItemDetails = try await loadResourceDetails(items.map(\.resourceAddress))
//
//                let tokens = try await allItemDetails.parallelMap { item in
//                        try await createNonFungibleToken(accountAddress, details: item)
//                }
//
//                return tokens
//        }
//
//        static func createNonFungibleToken(_ accountAddress: AccountAddress, details: GatewayAPI.StateEntityDetailsResponseItem) async throws -> AccountPortfolio.NonFungibleToken {
//                let vaults = try await loadAllEntityNonFungibleTokenVaults(accountAddress, details.address)
//                let totalAmount = vaults.reduce(0) { partialResult, item in
//                        partialResult + item.totalCount
//                }
//
//                return AccountPortfolio.NonFungibleToken(
//                        resourceAddress: .init(address: details.address),
//                        name: details.metadata.name,
//                        description: details.metadata.description,
//                        amount: totalAmount
//                )
//        }
//
//        static func loadAllEntityNonFungibleTokenVaults(
//                _ accountAddress: AccountAddress,
//                _ resourceAddress: String,
//                _ page: (loadedItems: [GatewayAPI.NonFungibleResourcesCollectionItemVaultAggregatedVaultItem], nextPageCursor: PageCursor?)? = nil
//        ) async throws -> [GatewayAPI.NonFungibleResourcesCollectionItemVaultAggregatedVaultItem] {
//
//                // TODO: How can  we be sure that we don't end in an infinite loop?
//                if let page, page.nextPageCursor == nil {
//                        return page.loadedItems
//                }
//
//                let items = page?.loadedItems ?? []
//                let nextPageCursor = page?.nextPageCursor
//
//                let (newItems, cursor) = try await loadEntityNonFungibleTokenVaultPage(accountAddress, resourceAddress: resourceAddress, pageCursor: nextPageCursor)
//
//                return try await loadAllEntityNonFungibleTokenVaults(accountAddress, resourceAddress, (items + newItems, cursor))
//        }
//
//        @Sendable
//        static func loadEntityNonFungibleTokenVaultPage(_ accountAddress: AccountAddress, resourceAddress: String, pageCursor: PageCursor?) async throws -> (items: [GatewayAPI.NonFungibleResourcesCollectionItemVaultAggregatedVaultItem], nextPageCursor: PageCursor?) {
//                @Dependency(\.gatewayAPIClient) var gatewayAPIClient
//
//                let request = GatewayAPI.StateEntityNonFungibleResourceVaultsPageRequest(
//                        atLedgerState: pageCursor?.ledgerState.selector,
//                        cursor: pageCursor?.nextPagCursor,
//                        limitPerPage: 20,
//                        address: accountAddress.address,
//                        resourceAddress: resourceAddress
//                )
//                let response = try await gatewayAPIClient.getEntityNonFungibleResourceVaultPage(request)
//
//                let nextPageCursor: PageCursor? = {
//                        guard !response.items.isEmpty else {
//                                return nil
//                        }
//
//                        return response.nextCursor.map { PageCursor(ledgerState: response.ledgerState, nextPagCursor: $0) }
//                }()
//
//                return (response.items, nextPageCursor)
//        }
//}
//
////extension Prelude.LedgerState {
////        var toGateway: GatewayAPI.LedgerState {
////                .init(network: network, stateVersion: stateVersion, proposerRoundTimestamp: proposerRoundTimestamp, epoch: epoch, round: round)
////        }
////
//////        public init(from gateway: GatewayAPI.LedgerStateSelector) {
//////                self.init(network: gateway.network,
//////                          stateVersion: gateway.stateVersion,
//////                          proposerRoundTimestamp: gateway.proposerRoundTimestamp,
//////                          epoch: gateway.epoch,
//////                          round: gateway.round)
//////        }
////}
//
//extension AccountPortfoliosClient {
////        @Sendable
////        static func fetchMoreFungibleTokens(_ accountAddress: AccountAddress, nextPageCursor: String) async throws -> (tokens: [AccountPortfolio.FungibleToken], nextPageCursor: String?) {
////                @Dependency(\.gatewayAPIClient) var gatewayAPIClient
////
////                let response = try await gatewayAPIClient.getEntityFungibleTokensPage(
////                        .init(cursor: nextPageCursor, limitPerPage: 20, address: accountAddress.address)
////                )
////
////                let fungibleTokens = try await createFungibleResources(response.items)
////
////                return (fungibleTokens, response.nextCursor)
////        }
//}
//
//extension AccountPortfoliosClient {
//        @Sendable
//        static func fetchMoreNonFungibleTokens(_ accountAddress: AccountAddress, nextPageCursor: String) async throws -> (tokens: [AccountPortfolio.NonFungibleToken], nextPageCursor: String?) {
//                fatalError("TODO: Implement")
//                //                let response = try await gatewayAPIClient.getEntity(
//                //                        .init(cursor: nextPageCursor, limitPerPage: 20, address: accountAddress.address)
//                //                )
////
//                //                let fungibleTokens = try await createFungibleTokens(response.items)
////
//                //                return (fungibleTokens, response.nextCursor)
//        }
//}
//
//extension AccountPortfoliosClient {
//        @Sendable
//        static func createFungibleResources(_ items: [GatewayAPI.FungibleResourcesCollectionItem]) async throws -> [State.FungibleResource] {
//                let items = items.compactMap(\.global)
//                let allItemDetails = try await loadResourceDetails(items.map(\.resourceAddress))
//
//                let tokens = allItemDetails.map { itemDetails in
//                        State.FungibleResource(
//                                address: itemDetails.address,
//                                metadata: itemDetails.metadata,
//                                content: items.first { $0.resourceAddress == itemDetails.address}!,
//                                details: itemDetails.details?.fungible)
//                }
//
//                return tokens
//        }
//}

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
