import AppSettings
import Asset
import Dependencies
import GatewayAPI
import Profile

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
