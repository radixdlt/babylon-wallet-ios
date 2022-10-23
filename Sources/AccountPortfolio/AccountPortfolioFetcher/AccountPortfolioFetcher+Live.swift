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

// extension AccountPortfolio {
//	init(assetMatrix: [[any Asset]]) {
//        var fungibleTokenContainers: [FungibleTokenContainer] = []
//        var nonFungibleTokenContainers: [NonFungibleTokenContainer] = []
//       var poolShareContainers: [PoolShareContainer] = []
//       var badgeContainers: [BadgeContainer] = []
//
//        for list in assetMatrix {
//            if let fungibleTokens = list as? [FungibleToken] {
//                fungibleTokenContainers = fungibleTokens.map { (fungibleToken: FungibleToken) in
//                    FungibleTokenContainer.init(asset: fungibleToken, amount: <#T##Float?#>, worth: <#T##Float?#>)
//                }
//            } else if let nonFungibleTokens = list as? [NonFungibleToken] {
//
//            } else if let nonFungibleTokens = list as? [NonFungibleToken] {
//
//            } else if let nonFungibleTokens = list as? [NonFungibleToken] {
//
//            } else {
//                fatalError("Did you mix assets together? Not supported...")
//            }
//        }
//	}
// }
