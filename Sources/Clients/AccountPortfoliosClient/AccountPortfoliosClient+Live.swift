import CacheClient
import ClientPrelude
import GatewayAPI
import SharedModels

// MARK: - AccountPortfoliosClient + DependencyKey
extension AccountPortfoliosClient: DependencyKey {
        actor State {
                struct PaginatedResource<Item: Hashable>: Hashable, Sendable {
                        internal init(cursor: PageCursor? = nil, totalCount: Int64?, items: [Item]) {
                                self.cursor = cursor
                                self.totalCount = totalCount.map(Int.init) ?? items.count
                                self.items = items
                        }

                        let cursor: PageCursor?
                        let totalCount: Int
                        let items: [Item]
                }

                struct NonFungibleResource: Hashable, Sendable {
                        typealias Vaults = PaginatedResource<GatewayAPI.NonFungibleResourcesCollectionItemVaultAggregatedVaultItem>
                        typealias OwnedIds = PaginatedResource<GatewayAPI.NonFungibleIdsCollectionItem>
                        struct Details: Hashable, Sendable {
                                let metadata: GatewayAPI.EntityMetadataCollection?
                                let resourceDetails: GatewayAPI.StateEntityDetailsResponseNonFungibleResourceDetails?
                        }

                        let address: String
                        let vaults: Vaults

                        // Optional when not loaded
                        let details: Details?
                        let ownedIds: OwnedIds?
                }

                struct FungibleResource: Hashable, Sendable {
                        struct Details: Hashable, Sendable {
                                let metadata: GatewayAPI.EntityMetadataCollection
                                let resourceDetails: GatewayAPI.StateEntityDetailsResponseFungibleResourceDetails?
                        }
                        typealias Vaults = PaginatedResource<GatewayAPI.FungibleResourcesCollectionItemVaultAggregatedVaultItem>

                        let address: String
                        let vaults: Vaults

                        // Optional when not loaded
                        let details: Details?
                }

                struct AccountResources: Hashable, Sendable {
                        typealias FungibleResources = PaginatedResource<FungibleResource>
                        typealias NonFungibleResources = PaginatedResource<NonFungibleResource>

                        let owner: AccountAddress
                        let fungibleResources: FungibleResources?
                        let nonFungibleResources: NonFungibleResources?
                }

                private var accountResources: Set<AccountResources>

                init(accountResources: Set<AccountResources>) {
                        self.accountResources = accountResources
                }

                func setAccountResources(_ resources: Set<AccountResources>) {
                        self.accountResources = resources
                }
        }

        public static let liveValue: AccountPortfoliosClient = {
                let portfolios: AsyncCurrentValueSubject<Set<AccountPortfolio>> = .init([])
                let state = State(accountResources: [])

                return AccountPortfoliosClient(
                        fetchAccountPortfolios: { accountAddresses in
                                let loadedResources = try await fetchAccountResources(accountAddresses)
                                await state.setAccountResources(Set(loadedResources))
                                let accountPortfolios = try await state.accountPortfolio()
                                portfolios.value = Set(accountPortfolios)
                                return accountPortfolios
                        },
                        fetchAccountPortfolio: { address, refresh in
                                let portfolio = try await fetchAccountPortfolio(address)
                                portfolios.value.update(with: portfolio)
                                return portfolio
                        },
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

extension AccountPortfoliosClient.State {
        func accountPortfolio() throws -> [AccountPortfolio] {
                try self.accountResources.map {
                        let fungibleResources = try $0.fungibleResources?.items.map { resource in
                                let details = resource.details
                                let amount = try BigDecimal(fromString: "0")

                                return AccountPortfolio.FungibleResource(
                                        resourceAddress: .init(address: resource.address),
                                        amount: amount,
                                        divisibility: details?.resourceDetails?.divisibility,
                                        name: details?.metadata.name,
                                        symbol: details?.metadata.symbol,
                                        description: details?.metadata.description
                                )
                        }

                        let nonFungibleResources = $0.nonFungibleResources?.items.map { resource in
                                return AccountPortfolio.NonFungibleResource(
                                        resourceAddress: .init(address: resource.address),
                                        name: resource.details?.metadata?.name,
                                        ids: .init(totalCount: 10)
                                )
                        }


                        return AccountPortfolio(owner: $0.owner,
                              fungibleResources: .init(totalCount: $0.fungibleResources?.totalCount ?? 0, items: fungibleResources),
                              nonFungibleResources: .init(totalCount: $0.nonFungibleResources?.totalCount ?? 0, items: nonFungibleResources))
                }
        }
}


extension AccountPortfoliosClient {
        static func fetchAccountResources(_ accountAddresses: [AccountAddress]) async throws -> [State.AccountResources] {
                let allDetails = try await loadResourceDetails(accountAddresses.map(\.address))
                return try allDetails.items.map(createBaseAccountResources(allDetails.ledgerState))
        }

        static func createBaseAccountResources(
                _ ledgerState: GatewayAPI.LedgerState
        ) -> (GatewayAPI.StateEntityDetailsResponseItem) throws -> State.AccountResources {
                return { details in
                        let nonFungibleResources = details.nonFungibleResources.map(createBaseNonFungibleResources(ledgerState))
                        let fungibleResources = details.fungibleResources.map(createBaseFungibleResources(ledgerState))

                        return try .init(
                                owner: .init(address: details.address),
                                fungibleResources: fungibleResources,
                                nonFungibleResources: nonFungibleResources
                        )
                }
        }

        static func createBaseNonFungibleResources(
                _ ledgerState: GatewayAPI.LedgerState
        ) -> (GatewayAPI.NonFungibleResourcesCollection) -> State.AccountResources.NonFungibleResources {
                return { collection in
                        let items = collection.items
                                .compactMap(\.vault)
                                .map { item in
                                        State.NonFungibleResource(
                                                address: item.resourceAddress,
                                                vaults: .init(totalCount: item.vaults.totalCount, items: item.vaults.items),
                                                metadata: nil,
                                                details: nil,
                                                ownedIds: nil
                                        )
                                }

                        return .init(
                                cursor: collection.nextCursor.map { PageCursor(ledgerState: ledgerState, nextPagCursor: $0 )},
                                totalCount: collection.totalCount,
                                items: items
                        )
                }
        }

        static func createBaseFungibleResources(
                _ ledgerState: GatewayAPI.LedgerState
        ) -> (GatewayAPI.FungibleResourcesCollection) -> State.AccountResources.FungibleResources {
                return { collection in
                        let items = collection.items
                                .compactMap(\.vault)
                                .map { item in
                                        State.FungibleResource(
                                                address: item.resourceAddress,
                                                vaults: .init(totalCount: nil, items: item.vaults.items),
                                                metadata: nil,
                                                details: nil
                                        )
                                }

                        return .init(
                                cursor: collection.nextCursor.map { PageCursor(ledgerState: ledgerState, nextPagCursor: $0 )},
                                totalCount: collection.totalCount,
                                items: items
                        )
                }
        }

        // Load single account portfolio preview
        static func fetchAccountPortfolio(_ accountAddress: AccountAddress) async throws -> AccountPortfolio {
                // Use entity details endpoint actually
                async let fetchFungibleResources = fetchAccountFungibleResources(accountAddress)
                async let fetchNonFungibleResources = fetchAccountNonFungibleResources(accountAddress)

                let (fungibleResources, nonFungiblResources) = try await (fetchFungibleResources, fetchNonFungibleResources)

                return .init(
                        owner: accountAddress,
                        fungibleResources: fungibleResources,
                        nonFungibleResources: nonFungiblResources
                )
        }

//        let allFungibleResourceItems: [GatewayAPI.FungibleResourcesCollectionItem]? = details.fungibleResources.map { fungibleResources in
//                var items = fungibleResources.items
//                if let nextPageCursor = fungibleResources.nextPagCursor {
//                        let additionalItems = try await fetchAllPaginatedItems(
//                                cursor: PageCursor(ledgerState: ledgerState, nextPagCursor: nextPageCursor),
//                                fetchNonFungibleResourcePage(accountAddress)
//                        )
//                        items.append(contentsOf: additionalItems)
//                }
//                return items
//        }()
}

extension Optional {
        func asyncMap<T>(_ transform: @Sendable (Wrapped) async throws -> T) async throws -> Optional<T> {
                guard case let .some(value) = self else {
                        return nil
                }

                return try await transform(value)
        }
}

extension AccountPortfoliosClient {
//        static func fetchAccountFungibleResources(_ accountAddress: AccountAddress) async throws -> AccountPortfolio.FungibleResources {
//                let allResources = try await fetchAllPaginatedItems(fetchAccountFungibleResourcePage(accountAddress)).compactMap(\.global)
//                let allDetails = try await loadResourceDetails(allResources.map(\.resourceAddress))
//
//                return try allDetails.map { item in
//                        let amount = allResources.first { $0.resourceAddress == item.address }?.amount ?? "0"
//                        return try AccountPortfolio.FungibleResource(
//                                resourceAddress: .init(address: item.address),
//                                amount: .init(fromString: amount),
//                                divisibility: item.details?.fungible?.divisibility,
//                                name: item.metadata.name,
//                                symbol: item.metadata.symbol,
//                                tokenDescription: item.metadata.description
//                        )
//                }
//        }
//
//        static func fetchAccountNonFungibleResources(_ accountAddress: AccountAddress) async throws -> AccountPortfolio.NonFungibleResources {
//                let allResources = try await fetchAllPaginatedItems(fetchNonFungibleResourcePage(accountAddress)).compactMap(\.vault)
//                let allDetails = try await loadResourceDetails(allResources.map(\.resourceAddress))
//
//                return try await allResources.map(\.resourceAddress)
//                        .parallelMap { resourceAddress in
//                               try await createAccountNonFungibleResource(
//                                        accountAddress,
//                                        resourceAddress: resourceAddress,
//                                        metadata: allDetails.first(where: { $0.address == resourceAddress })?.metadata
//                                )
//                        }
//        }
//
//        static func createAccountNonFungibleResource(
//                _ accountAddress: AccountAddress,
//                resourceAddress: String,
//                metadata: GatewayAPI.EntityMetadataCollection?
//        ) async throws -> AccountPortfolio.NonFungibleResource {
//                let vaults = try await fetchAllPaginatedItems(fetchEntityNonFungibleResourceVaultPage(accountAddress, resourceAddress: resourceAddress))
//                let ids = try await vaults.map(\.vaultAddress)
//                        .parallelMap { vaultAddress in
//                                try await fetchAllPaginatedItems(fetchEntityNonFungibleResourceIdsPage(
//                                        accountAddress,
//                                        resourceAddress: resourceAddress,
//                                        vaultAddress: vaultAddress
//                                ))
//                        }
//                        .flatMap { $0 }
//                        .map(\.nonFungibleId)
//
//                return .init(resourceAddress: .init(address: resourceAddress),
//                             name: metadata?.name,
//                             description: metadata?.description,
//                             ids: ids
//                )
//        }
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
                cursor: PageCursor,
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

                return try await fetchAllPaginatedItems(collectedResources: .init(loadedItems: [], totalCount: nil, cursor: cursor))
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
                                cursor: response.nextCursor.map {PageCursor(ledgerState: response.ledgerState, nextPagCursor: $0)}
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
                                cursor: response.nextCursor.map { PageCursor(ledgerState: response.ledgerState, nextPagCursor: $0)}
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
                                cursor: response.nextCursor.map { PageCursor(ledgerState: response.ledgerState, nextPagCursor: $0)}
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
                                cursor: response.nextCursor.map { PageCursor(ledgerState: response.ledgerState, nextPagCursor: $0)}
                        )
                }
        }

        struct EmptyDetailsResponses: Error {}

        static let entityDetailsPageSize = 20
        @Sendable
        static func loadResourceDetails(_ addresses: [String]) async throws -> GatewayAPI.StateEntityDetailsResponse {
                @Dependency(\.gatewayAPIClient) var gatewayAPIClient

                let responses = try await addresses
                        .chunks(ofCount: entityDetailsPageSize)
                        .map(Array.init)
                        .parallelMap(gatewayAPIClient.getEntityDetails)

                let allItems = responses.flatMap(\.items)
                guard let ledgerState = responses.first?.ledgerState else {
                        throw EmptyDetailsResponses()
                }

                return .init(ledgerState: ledgerState, items: allItems)
        }
}

// MARK: - AccountPortfoliosClient + TestDependencyKey
extension AccountPortfoliosClient: TestDependencyKey {
        public static let previewValue = AccountPortfoliosClient.noop

        public static let testValue = AccountPortfoliosClient(
                fetchAccountPortfolios: unimplemented("\(AccountPortfoliosClient.self).fetchAccountPortfolios"),
                fetchAccountPortfolio: unimplemented("\(AccountPortfoliosClient.self).fetchAccountPortfolio"),
                portfolioForAccount: unimplemented("\(AccountPortfoliosClient.self).portfolioForAccount"),
                portfolios: .init([])
        )

        public static let noop = AccountPortfoliosClient(
                fetchAccountPortfolios: { _ in throw NoopError() },
                fetchAccountPortfolio: { _, _ in throw NoopError() },
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
