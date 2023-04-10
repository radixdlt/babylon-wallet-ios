import ClientPrelude
import GatewayAPI
import EngineToolkitClient

// MARK: - AccountPortfolioFetcherClient + DependencyKey
extension AccountPortfolioFetcherClient: DependencyKey {
	public static let liveValue: Self = {
                let pageSize = 20

                @Dependency(\.gatewayAPIClient) var gatewayAPIClient
                @Dependency(\.engineToolkitClient) var engineToolkitClient

                @Sendable
                func createNonFungibleToken(
                        _ accountAddress: AccountAddress
                ) -> (GatewayAPI.StateEntityDetailsResponseItem) async throws -> NonFungibleTokenContainer {
                        return { tokenDetails in
                                let resourceAddress = ResourceAddress(address: tokenDetails.address)
                                let metadata = tokenDetails.metadata

                                let idsResponse = try await gatewayAPIClient.getNonFungibleIds(resourceAddress.address).nonFungibleIds
                                let idsCollection = PaginatedResourceContainer(
                                        loaded: idsResponse.items.map { NonFungibleToken(nonFungibleLocalId: .string($0.nonFungibleId)) },
                                        totalCount: idsResponse.totalCount.map(Int.init),
                                        nextPageCursor: idsResponse.nextCursor
                                )

                                return NonFungibleTokenContainer(
                                        owner: accountAddress,
                                        resourceAddress: resourceAddress,
                                        assets: idsCollection,
                                        name: metadata.name,
                                        description: metadata.description,
                                        iconURL: nil)
                        }
                }

                @Sendable
                func createFungibleToken(
                        _ accountAddress: AccountAddress,
                        allTokens: [GatewayAPI.FungibleResourcesCollectionItemGloballyAggregated],
                        networkID: NetworkID) -> (GatewayAPI.StateEntityDetailsResponseItem
                        ) throws -> FungibleTokenContainer {
                        return { tokenDetails in
                                let resourceAddress = ResourceAddress(address: tokenDetails.address)
                                let metadata = tokenDetails.metadata
                                let isXRD = (try? engineToolkitClient.isXRD(resource: resourceAddress, on: networkID)) ?? false

                                let token = FungibleToken(
                                        resourceAddress: resourceAddress,
                                        divisibility: tokenDetails.details?.fungible?.divisibility,
                                        tokenDescription: metadata.description,
                                        name: metadata.name,
                                        symbol: metadata.symbol,
                                        isXRD: isXRD
                                )

                                let amount = allTokens.first(where: { $0.resourceAddress == resourceAddress.address })?.amount ?? "0"
                                return try FungibleTokenContainer(owner: accountAddress,
                                                                  asset: token,
                                                                  amount: BigDecimal(fromString: amount),
                                                                  worth: nil)
                        }
                }

                @Sendable
                func loadResourceDetails(_ addresses: [String]) async throws -> [GatewayAPI.StateEntityDetailsResponseItem] {
                        try await addresses
                                .chunks(ofCount: pageSize)
                                .map(Array.init)
                                .parallelMap(gatewayAPIClient.getEntityDetails)
                                .flatMap(\.items)
                }

		let fetchPortfolioForAccount: FetchPortfolioForAccount = { (accountAddress: AccountAddress) async throws -> AccountPortfolio in
                        let response = try await gatewayAPIClient.getAccountDetails(accountAddress)
                        let networkID = try Radix.Network.lookupBy(name: response.ledgerState.network).id

                        let accountDetails = response.details
                        let fungibleResources = accountDetails.fungibleResources
                        let nonFungibleResources = accountDetails.nonFungibleResources


                        let fungibleResourceItems = fungibleResources?.items.compactMap(\.global) ?? []
                        let nonFungibleResourceItems = nonFungibleResources?.items.compactMap(\.global) ?? []


                        let createFungibleToken = createFungibleToken(accountAddress, allTokens: fungibleResourceItems, networkID: networkID)
                        let createNonFungibleToken = createNonFungibleToken(accountAddress)
                        async let loadFungibleResourceContainer = loadResourceDetails(fungibleResourceItems.map(\.resourceAddress)).map(createFungibleToken)
                        async let loadNonFungibleResourceContainer = loadResourceDetails(nonFungibleResourceItems.map(\.resourceAddress)).asyncMap(createNonFungibleToken)

                        let (fungibleResourceContainers, nonFungbileResourceContainers) = try await (loadFungibleResourceContainer, loadNonFungibleResourceContainer)


                        return AccountPortfolio(owner: accountAddress,
                                                fungibleTokenContainers: .init(loaded: .init(uniqueElements: fungibleResourceContainers),
                                                                               totalCount: fungibleResources?.totalCount.map(Int.init),
                                                                               nextPageCursor: fungibleResources?.nextCursor),
                                                nonFungibleTokenContainers: .init(loaded: .init(uniqueElements: nonFungbileResourceContainers),
                                                                                  totalCount: nonFungibleResources?.totalCount.map(Int.init),
                                                                                  nextPageCursor: nonFungibleResources?.nextCursor),
                                                poolUnitContainers: [],
                                                badgeContainers: [])
		}

                func fetchFungibleTokens(_ accountAddress: AccountAddress, _ nextPageCursor: String?) async throws -> FungibleTokensPageResponse {
                        let response = try await gatewayAPIClient.getEntityFungibleTokensPage(
                                .init(cursor: nextPageCursor, limitPerPage: 20, address: accountAddress.address)
                        )
                        let networkID = try Radix.Network.lookupBy(name: response.ledgerState.network).id
                        let items = response.items.compactMap(\.global)
                        let itemDetails = try await loadResourceDetails(items.map(\.resourceAddress))

                        let createFungibleToken = createFungibleToken(accountAddress, allTokens: items, networkID: networkID)
                        let funbileTokens = try await itemDetails.asyncMap(createFungibleToken)
                        return .init(tokens: funbileTokens, nextPageCursor: response.nextCursor)
                }

		return Self(
			fetchPortfolioForAccount: fetchPortfolioForAccount,
			fetchPortfolioForAccounts: { addresses in

				let portfolios = try await withThrowingTaskGroup(
					of: AccountPortfolio.self,
					returning: IdentifiedArrayOf<AccountPortfolio>.self,
					body: { taskGroup in
						for address in addresses {
							_ = taskGroup.addTaskUnlessCancelled {
								try await fetchPortfolioForAccount(address)
							}
						}
						var portfolios: IdentifiedArrayOf<AccountPortfolio> = .init()
						for try await result in taskGroup {
							portfolios[id: result.id] = result
						}

						return portfolios
					}
				)

				return portfolios
                        },
                        fetchFungibleTokens: <#AccountPortfolioFetcherClient.FetchFungibleTokens#>
		)
	}()
}

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


extension GatewayAPI.StateEntityDetailsResponse: @unchecked Sendable {}

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
extension AccountPortfolioFetcherClient {
	public func fetchXRDBalance(
		of accountAddress: AccountAddress,
		on networkID: NetworkID
	) async -> FungibleTokenContainer? {
		guard let portfolio = try? await fetchPortfolioForAccount(accountAddress) else {
			return nil
		}
                return portfolio
                        .fungibleTokenContainers
                        .loaded
			.first(where: \.asset.isXRD)
	}
}

// MARK: - AccountPortfolioFetcherClient.Error
extension AccountPortfolioFetcherClient {
	public enum Error: Swift.Error {
		case failedToFetchXRD
	}
}
