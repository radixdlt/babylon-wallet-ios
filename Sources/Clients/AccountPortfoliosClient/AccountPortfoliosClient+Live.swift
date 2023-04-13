import ClientPrelude
import GatewayAPI
import SharedModels

extension AccountPortfoliosClient: DependencyKey {
        public static let liveValue: AccountPortfoliosClient = {
                let portfolios: AsyncCurrentValueSubject<Set<AccountPortfolio>> = .init([])
                
                return AccountPortfoliosClient(
                        fetchAccountPortfolios: { accountAddresses in
                                let loadedPortfolios = try await fetchAccountPortfolios(accountAddresses)
                                portfolios.value = Set(loadedPortfolios)
                                return loadedPortfolios
                        },
                        fetchAccountPortfolio: { address in
                                let portfolio = try await fetchAccountPortfolio(address)
                                portfolios.value.update(with: portfolio)
                                return portfolio
                        },
                        fetchMoreFungibleTokens: { accountAddress in
                                guard var portfolio = portfolios.value.first(where: { $0.owner == accountAddress }),
                                let nextPageCursor = portfolio.fungibleResources.nextPageCursor else {
                                        fatalError()
                                }

                                let (tokens, pageCursor) = try await fetchMoreFungibleTokens(accountAddress, nextPageCursor: nextPageCursor)
                                portfolio.fungibleResources.nextPageCursor = pageCursor
                                portfolio.fungibleResources.loaded.append(contentsOf: tokens)
                                portfolios.value.update(with: portfolio)
                                return portfolio
                        },
                        fetchMoreNonFungibleTokens: { accounAddress in
                                guard var portfolio = portfolios.value.first(where: { $0.owner == accounAddress }),
                                      let nextPageCursor = portfolio.nonFungibleResources.nextPageCursor else {
                                        fatalError()
                                }

                                let (tokens, pageCursor) = try await fetchMoreNonFungibleTokens(accounAddress, nextPageCursor: nextPageCursor)

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

extension AccountPortfoliosClient: TestDependencyKey {
        public static let previewValue = AccountPortfoliosClient.noop

        public static let testValue = AccountPortfoliosClient(
                fetchAccountPortfolios: unimplemented("\(AccountPortfoliosClient.self).fetchAccountPortfolios"),
                fetchAccountPortfolio: unimplemented("\(AccountPortfoliosClient.self).fetchAccountPortfolio"),
                fetchMoreFungibleTokens: unimplemented("\(AccountPortfoliosClient.self).fetchMoreFungibleTokens"),
                fetchMoreNonFungibleTokens: unimplemented("\(AccountPortfoliosClient.self).fetchMoreNonFungibleTokens"),
                portfolioForAccount: unimplemented("\(AccountPortfoliosClient.self).portfolioForAccount"),
                portfolios: .init([])
        )

        public static let noop = AccountPortfoliosClient(
                fetchAccountPortfolios: { _ in throw NoopError() },
                fetchAccountPortfolio: { _ in throw NoopError() },
                fetchMoreFungibleTokens: { _ in throw NoopError() },
                fetchMoreNonFungibleTokens: { _ in throw NoopError() },
                portfolioForAccount: { _ in fatalError() },
                portfolios: .init([])
        )
}

extension AccountPortfoliosClient {
        static let fetchAccountPortfolios: FetchAccountPortfolios = { addresses in
                @Dependency(\.gatewayAPIClient) var gatewayAPIClient
                return try await loadResourceDetails(addresses.map(\.address))
                        .parallelMap(createAccountPortfolio)
        }
}

extension AccountPortfoliosClient {
        static let fetchAccountPortfolio: FetchAccountPortfolio = { accountAddress in
                @Dependency(\.gatewayAPIClient) var gatewayAPIClient

                let response = try await gatewayAPIClient.getAccountDetails(accountAddress)
                return try await createAccountPortfolio(response.details)
        }

        @Sendable
        static func createAccountPortfolio(_ accountDetails: GatewayAPI.StateEntityDetailsResponseItem) async throws -> AccountPortfolio {
                let fungibleResources = accountDetails.fungibleResources
                let nonFungibleResources = accountDetails.nonFungibleResources

                async let createFungibleTokens = createFungibleTokens(fungibleResources!.items)
                async let createNonFungibleTokens = createNonFungibleTokens(nonFungibleResources!)

                let (fungibleTokens, nonFungibleTokens) = try await (createFungibleTokens, createNonFungibleTokens)

                return try AccountPortfolio.init(
                        owner: AccountAddress(address: accountDetails.address),
                        fungibleResources: .init(loaded: fungibleTokens),
                        nonFungibleResources: nonFungibleTokens
                )
        }
}

extension AccountPortfoliosClient {
        @Sendable
        static func fetchMoreFungibleTokens(_ accountAddress: AccountAddress, nextPageCursor: String) async throws -> (tokens: [AccountPortfolio.FungibleToken], nextPageCursor: String?) {
                @Dependency(\.gatewayAPIClient) var gatewayAPIClient

                let response = try await gatewayAPIClient.getEntityFungibleTokensPage(
                        .init(cursor: nextPageCursor, limitPerPage: 20, address: accountAddress.address)
                )

                let fungibleTokens = try await createFungibleTokens(response.items)

                return (fungibleTokens, response.nextCursor)
        }
}

extension AccountPortfoliosClient {
        @Sendable
        static func fetchMoreNonFungibleTokens(_ accountAddress: AccountAddress, nextPageCursor: String) async throws -> (tokens: [AccountPortfolio.NonFungibleToken], nextPageCursor: String?) { 
                fatalError("TODO: Implement")
//                let response = try await gatewayAPIClient.getEntity(
//                        .init(cursor: nextPageCursor, limitPerPage: 20, address: accountAddress.address)
//                )
//
//                let fungibleTokens = try await createFungibleTokens(response.items)
//
//                return (fungibleTokens, response.nextCursor)
        }
}

extension AccountPortfoliosClient {
        @Sendable
        static func createFungibleTokens(_ items: [GatewayAPI.FungibleResourcesCollectionItem]) async throws -> [AccountPortfolio.FungibleToken] {
                let items = items.compactMap(\.global)

                // TODO: This most probably will change. The GW should be improved to return the well-known metadata along with the amount.
                let amounts = items.reduce(into: [String: String]()) { partialResult, item in
                        partialResult[item.resourceAddress] = item.amount
                }

                // This will most probably go away - the GW should return the details in `FungibleResourcesCollectionItem`
                let allItemDetails = try await loadResourceDetails(items.map(\.resourceAddress))

                let tokens = try allItemDetails.map {
                        let rawAmount = amounts[$0.address] ?? "0"
                        let amount = try BigDecimal(fromString: rawAmount)

                        return AccountPortfolio.FungibleToken(
                                resourceAddress: .init(address: $0.address),
                                amount: amount,
                                divisibility: $0.details?.fungible?.divisibility,
                                name: $0.metadata.name,
                                symbol: $0.metadata.symbol,
                                tokenDescription: $0.metadata.description
                        )
                }

                return tokens
        }


        @Sendable
        static func createNonFungibleTokens(_ collection: GatewayAPI.NonFungibleResourcesCollection) async throws -> PaginatedResourceContainer<[AccountPortfolio.NonFungibleToken]> {
                @Dependency(\.gatewayAPIClient) var gatewayAPIClient

                let items = collection.items.compactMap(\.global)

                // TODO: This most probably will change. The GW should be improved to return the well-known metadata along with the amount.
                let amounts = items.reduce(into: [String: Int]()) { partialResult, item in
                        partialResult[item.resourceAddress] = Int(item.amount)
                }

                // This will most probably go away - the GW should return the details in `FungibleResourcesCollectionItem`
                let allItemDetails = try await loadResourceDetails(items.map(\.resourceAddress))

                let tokens = try await allItemDetails.parallelMap { item in
                        let amount = amounts[item.address] ?? 0
                        let idsResponse = try await gatewayAPIClient.getNonFungibleIds(item.address).nonFungibleIds

                        let ids = PaginatedResourceContainer(
                                loaded: idsResponse.items.map(\.nonFungibleId),
                                totalCount: idsResponse.totalCount.map(Int.init),
                                nextPageCursor: idsResponse.nextCursor
                        )

                        return AccountPortfolio.NonFungibleToken(
                                resourceAddress: .init(address: item.address),
                                name: item.metadata.name,
                                description: item.metadata.description,
                                amount: amount,
                                ids: ids)
                }

                return .init(loaded: tokens, totalCount: collection.totalCount.map(Int.init), nextPageCursor: collection.nextCursor)
        }
}

extension AccountPortfoliosClient {
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

extension GatewayAPI.StateEntityDetailsResponse: @unchecked Sendable {}

// TODO: Move to shared utils
extension Array where Element: Sendable {
        func parallelMap<T: Sendable>(_ map: @Sendable @escaping (Element) async throws -> T) async throws-> [T] {
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
