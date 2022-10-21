import AppSettings
import Asset
import Profile

public extension AccountPortfolioFetcher {
	private typealias AssetsDictionaryPerAccountAddress = [AccountAddress: [[any Asset]]]

	static func live(
		assetFetcher: AssetFetcher = .live,
		assetUpdater: AssetUpdater = .live,
		appSettingsClient: AppSettingsClient = .live()
	) -> Self {
		Self(
			fetchPortfolio: { addresses in
				let portfolioDictionary = try await withThrowingTaskGroup(
					of: (address: AccountAddress, assets: [[any Asset]]).self,
					returning: AssetsDictionaryPerAccountAddress.self,
					body: { taskGroup in
						for address in addresses {
							taskGroup.addTask {
								let assets = try await assetFetcher.fetchAssets(address)
								return (address, assets)
							}
						}

						var portfolioDictionary = AssetsDictionaryPerAccountAddress()
						for try await result in taskGroup {
							portfolioDictionary[result.address] = result.assets
						}

						return portfolioDictionary
					}
				)

				let currency = try await appSettingsClient.loadSettings().currency

				let accountsPortfolio = try await withThrowingTaskGroup(
					of: (address: AccountAddress, portfolio: AccountPortfolio).self,
					returning: AccountPortfolioDictionary.self,
					body: { taskGroup in
						for element in portfolioDictionary {
							taskGroup.addTask {
								let address = element.key
								let assets = element.value
								let assetContainers = try await assetUpdater.updateAssets(assets, currency)
								return (address, assetContainers)
							}
						}

						var portfolio = AccountPortfolioDictionary()
						for try await result in taskGroup {
							portfolio[result.address] = AccountPortfolio(
								fungibleTokenContainers: result.portfolio.fungibleTokenContainers,
								nonFungibleTokenContainers: result.portfolio.nonFungibleTokenContainers,
								poolShareContainers: result.portfolio.poolShareContainers,
								badgeContainers: result.portfolio.badgeContainers
							)
						}
						return portfolio
					}
				)

				return accountsPortfolio
			}
		)
	}
}
