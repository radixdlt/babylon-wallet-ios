import ClientPrelude
import GatewayAPI

// MARK: - AccountPortfolioFetcherClient + DependencyKey
extension AccountPortfolioFetcherClient: DependencyKey {
	public static let liveValue: Self = {
		let fetchPortfolioForAccount: FetchPortfolioForAccount = { (accountAddress: AccountAddress) async throws -> AccountPortfolio in
			@Dependency(\.gatewayAPIClient) var gatewayAPIClient

			let resourcesResponse = try await gatewayAPIClient.getAccountDetails(accountAddress)
			var accountPortfolio = try AccountPortfolio(owner: accountAddress, response: resourcesResponse)

			let tmpMaxRequestAmount = 999 // TODO: remove once pagination is implemented
			let fungibleTokenAddresses = Array(accountPortfolio.fungibleTokenContainers.map(\.asset.resourceAddress).prefix(tmpMaxRequestAmount))
			let nonFungibleTokenAddresses = Array(accountPortfolio.nonFungibleTokenContainers.map(\.resourceAddress).prefix(tmpMaxRequestAmount))

			if fungibleTokenAddresses.isEmpty, nonFungibleTokenAddresses.isEmpty {
				return .empty(owner: accountAddress)
			}

			if !fungibleTokenAddresses.isEmpty {
				let response = try await gatewayAPIClient.getEntityDetails(fungibleTokenAddresses.map(\.address))
				accountPortfolio.updateFungibleTokens(with: response)
			}

			if !nonFungibleTokenAddresses.isEmpty {
				let response = try await gatewayAPIClient.getEntityDetails(nonFungibleTokenAddresses.map(\.address))
				accountPortfolio.updateNonFungibleTokens(with: response)

				try await withThrowingTaskGroup(
					of: (ComponentAddress, [String]).self,
					returning: Void.self,
					body: { taskGroup in
						for resourceAddress in nonFungibleTokenAddresses {
							taskGroup.addTask {
								try Task.checkCancellation()
								let response = try await gatewayAPIClient.getNonFungibleIds(resourceAddress.address)

								let nonFungibleLocalIds = response.nonFungibleIds.items.map(\.nonFungibleId)
								return (resourceAddress, nonFungibleLocalIds)
							}
						}

						for try await result in taskGroup {
							accountPortfolio.updateNonFungibleTokens(
								idsResponse: result
							)
						}
					}
				)
			}

			return accountPortfolio
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
			}
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

extension AccountPortfolioFetcherClient {
        typealias FungibleResourceCollection = ResourceCollection<FungibleToken>
        typealias NonFungibleResourceCollection = ResourceCollection<NonFungibleToken>
        struct ResourceCollection<Resource> {
                var totalCount: Int
                var loaded: [Resource]

                // The cursor for the next page to load if present
                var nextPageCursor: String?
        }

        static func fetchPortfolioForAccount(_ accountAddress: AccountAddress) async throws {
                @Dependency(\.gatewayAPIClient) var gatewayAPIClient
                @Dependency(\.engineToolkitClient) var engineToolkitClient

                var accountDetailsResponse = try await gatewayAPIClient.getAccountDetails(accountAddress)
                let fungibleResources = accountDetailsResponse.details.fungibleResources
                let nonFungibleResources = accountDetailsResponse.details.nonFungibleResources

                let networkID = try Radix.Network.lookupBy(name: accountDetailsResponse.ledgerState.network).id

                let pageSize = 19 // TODO: remove once pagination is implemented
                let fungibleTokenAddresses = fungibleResources?.items.compactMap(\.global?.resourceAddress).chunks(ofCount: pageSize).map(Array.init)
                let nonFungibleTokenAddresses = nonFungibleResources?.items.compactMap(\.global?.resourceAddress).chunks(ofCount: pageSize).map(Array.init)

                let (fungibleTokenDetails, nonFungibleTokenDetails) = try await Task {
                        async let fungibleTokenDetails = try fungibleTokenAddresses?
                                .parallelMap(gatewayAPIClient.getEntityDetails)
                                .compactMap(\.items.first)
                                .map { response in
                                let resourceAddress = ResourceAddress(address: response.address)
                                let metadata = response.metadata
                                let isXRD = (try? engineToolkitClient.isXRD(resource: resourceAddress, on: networkID)) ?? false

                                let token = FungibleToken(
                                        resourceAddress: resourceAddress,
                                              divisibility: response.details?.fungible?.divisibility,
                                              tokenDescription: metadata.description,
                                              name: metadata.name,
                                              symbol: metadata.symbol,
                                              isXRD: isXRD
                                )

                                return FungibleTokenContainer(owner: accountAddress, asset: token, amount: resp, worth: <#T##BigDecimal?#>)

                        }
                        async let nonFungibleTokenDetails = try nonFungibleTokenAddresses?
                                .parallelMap(gatewayAPIClient.getEntityDetails)
                                .compactMap(\.items.first)
                                .map {

                                        return NonFungibleTokenContainer(owner: <#T##AccountAddress#>, resourceAddress: <#T##ComponentAddress#>, assets: <#T##[NonFungibleToken]#>, name: <#T##String?#>, description: <#T##String?#>, iconURL: <#T##URL?#>)
                                }

                        return try await (fungibleTokenDetails, nonFungibleTokenDetails)
                }.result.get()

                // for each token detail download its details

//                let fungibleResources = accountDetailsResponse.details.fungibleResources
//                if let nextCursor = fungibleResources?.nextCursor {
//                        // Load the rest of fungible resources info
//
//                }
//
//                let nonFungibleResources = accountDetailsResponse.details.nonFungibleResources
//
//                if let nextCursor = nonFungibleResources?.nextCursor {
//                        // Load the rest of non fungible resources info
//                }
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
		return portfolio.fungibleTokenContainers
			.first(where: \.asset.isXRD)
	}
}

// MARK: - AccountPortfolioFetcherClient.Error
extension AccountPortfolioFetcherClient {
	public enum Error: Swift.Error {
		case failedToFetchXRD
	}
}
