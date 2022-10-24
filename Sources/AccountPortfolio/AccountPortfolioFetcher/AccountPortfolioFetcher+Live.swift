import AppSettings
import Asset
import GatewayAPI
import Profile

public extension AccountPortfolioFetcher {
	private typealias AssetsDictionaryPerAccountAddress = [AccountAddress: OwnedAssets]

	static func live(
		gatewayAPIClient: GatewayAPIClient,
		appSettingsClient: AppSettingsClient = .live()
	) -> Self {
		Self.live(
			assetFetcher: .live(gatewayAPIClient: gatewayAPIClient),
			appSettingsClient: appSettingsClient
		)
	}

	static func live(
		assetFetcher: AssetFetcher = .live(),
		appSettingsClient _: AppSettingsClient = .live()
	) -> Self {
		Self(
			fetchPortfolio: { addresses in
				let portfolioDictionary = try await withThrowingTaskGroup(
					of: (address: AccountAddress, assets: OwnedAssets).self,
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

				return portfolioDictionary
			}
		)
	}
}
