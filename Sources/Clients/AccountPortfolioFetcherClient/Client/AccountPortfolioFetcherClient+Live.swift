import ClientPrelude
import GatewayAPI

private let tmpMaxRequestAmount = 999

// MARK: - AccountPortfolioFetcherClient + DependencyKey
extension AccountPortfolioFetcherClient: DependencyKey {
	public static let liveValue: Self = {
		let fetchPortfolioForAccount: FetchPortfolioForAccount = { (accountAddress: AccountAddress) async throws -> AccountPortfolio in
			@Dependency(\.gatewayAPIClient) var gatewayAPIClient

			let resourcesResponse = try await gatewayAPIClient.getAccountDetails(accountAddress)
			var accountPortfolio = try AccountPortfolio(owner: accountAddress, response: resourcesResponse)

			let fungibleTokenAddresses = Array(accountPortfolio.fungibleTokenContainers.map(\.asset.componentAddress).prefix(tmpMaxRequestAmount))
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
