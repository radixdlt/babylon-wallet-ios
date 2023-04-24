import CacheClient
import ClientPrelude
import GatewayAPI

// MARK: - AccountPortfolioFetcherClient + DependencyKey
extension AccountPortfolioFetcherClient: DependencyKey {
	public static let liveValue: Self = {
		let fetchPortfolioForAccount: FetchPortfolioForAccount = { accountAddress, forceRefresh async throws -> AccountPortfolio in
			@Dependency(\.gatewayAPIClient) var gatewayAPIClient
			@Dependency(\.cacheClient) var cacheClient

			let fetchPortfolioForAccount = {
				loggerGlobal.trace("📡 fetching new data from gateway: \(accountAddress.address)")

				let resourcesResponse = try await gatewayAPIClient.getAccountDetails(accountAddress)
				var accountPortfolio = try AccountPortfolio(owner: accountAddress, response: resourcesResponse)

				let tmpMaxRequestAmount = 999 // TODO: remove once pagination is implemented
				let fungibleTokenAddresses = Array(accountPortfolio.fungibleTokenContainers.map(\.asset.resourceAddress).prefix(tmpMaxRequestAmount))
				let nonFungibleTokenAddresses = Array(accountPortfolio.nonFungibleTokenContainers.map(\.resourceAddress).prefix(tmpMaxRequestAmount))

				if fungibleTokenAddresses.isEmpty, nonFungibleTokenAddresses.isEmpty {
					let empty: AccountPortfolio = .empty(owner: accountAddress)
					return empty
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

			return try await cacheClient.withCaching(
				cacheEntry: .accountPortfolio(.single(accountAddress.address)),
				forceRefresh: forceRefresh,
				request: fetchPortfolioForAccount
			)
		}

		return Self(
			fetchPortfolioForAccount: fetchPortfolioForAccount,
			fetchPortfolioForAccounts: { accountAddresses, forceRefresh in

				let portfolios = try await withThrowingTaskGroup(
					of: AccountPortfolio.self,
					returning: IdentifiedArrayOf<AccountPortfolio>.self,
					body: { taskGroup in
						for address in accountAddresses {
							_ = taskGroup.addTaskUnlessCancelled {
								try await fetchPortfolioForAccount(address, forceRefresh)
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

extension AccountPortfolioFetcherClient {
	public func fetchXRDBalance(
		of accountAddress: AccountAddress,
		forceRefresh: Bool
	) async -> FungibleTokenContainer? {
		guard let portfolio = try? await fetchPortfolioForAccount(accountAddress, forceRefresh) else {
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
