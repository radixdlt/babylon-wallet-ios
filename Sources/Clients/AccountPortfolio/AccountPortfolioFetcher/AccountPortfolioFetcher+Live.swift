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
						taskGroup.addTask {
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
	public func fetchXRDBalance(of accountAddress: AccountAddress, on networkID: NetworkID) async throws -> FungibleTokenContainer {
		let accountPortfolioDictionary = try await fetchPortfolio([accountAddress])
		let xrdContainer = accountPortfolioDictionary.first?.value.fungibleTokenContainers
			.first(where: \.asset.isXRD)

		if let xrdContainer = xrdContainer {
			return xrdContainer
		} else {
			throw Error.failedToFetchXRD
		}
	}
}

// MARK: - AccountPortfolioFetcher.Error
extension AccountPortfolioFetcher {
	public enum Error: Swift.Error {
		case failedToFetchXRD
	}
}
