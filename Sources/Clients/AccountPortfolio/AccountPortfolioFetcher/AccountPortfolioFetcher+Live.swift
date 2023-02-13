import AppSettings
import ClientPrelude
import GatewayAPI

// MARK: - AccountPortfolioFetcher + DependencyKey
extension AccountPortfolioFetcher: DependencyKey {
	public static let liveValue = Self(
		fetchPortfolio: { addresses in
			@Dependency(\.assetFetcher) var assetFetcher

			let portfolioDictionary = try await withThrowingTaskGroup(
				of: (address: AccountAddress, assets: AccountPortfolio).self,
				returning: AccountPortfolioDictionary.self,
				body: { taskGroup in
					for address in addresses {
						_ = taskGroup.addTaskUnlessCancelled {
							try Task.checkCancellation()
							let assets = try await assetFetcher.fetchAssets(address)
							return (address, assets)
						}
					}

					var portfolioDictionary = AccountPortfolioDictionary()
					for try await result in taskGroup {
						portfolioDictionary[result.address] = result.assets
					}

					return portfolioDictionary
				}
			)

			return portfolioDictionary
		}
	)
}

extension AccountPortfolioFetcher {
	public func fetchXRDBalance(of accountAddress: AccountAddress, on networkID: NetworkID) async -> FungibleTokenContainer? {
		guard let accountPortfolioDictionary = try? await fetchPortfolio([accountAddress]) else {
			return nil
		}
		return accountPortfolioDictionary.first?.value.fungibleTokenContainers
			.first(where: \.asset.isXRD)
	}
}

// MARK: - AccountPortfolioFetcher.Error
extension AccountPortfolioFetcher {
	public enum Error: Swift.Error {
		case failedToFetchXRD
	}
}
