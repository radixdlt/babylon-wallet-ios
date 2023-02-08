import AppSettings
import ClientPrelude
import GatewayAPI
import EngineToolkitClient

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

public extension AccountPortfolioFetcher {
	func fetchXRDBalance(of accountAddress: AccountAddress, on networkID: NetworkID) async throws -> FungibleTokenContainer {
		let accountPortfolioDictionary = try await fetchPortfolio([accountAddress])
		@Dependency(\.engineToolkitClient) var engineToolkit
		let xrdContainer = accountPortfolioDictionary.first?.value.fungibleTokenContainers
			.first { engineToolkit.isXRD(component: $0.asset.componentAddress, on: networkID) }
		
		if let xrdContainer = xrdContainer {
			return xrdContainer
		} else {
			throw Error.failedToFetchXRD
		}
	}
}

// MARK: - AccountPortfolioFetcher.Error
public extension AccountPortfolioFetcher {
	enum Error: Swift.Error {
		case failedToFetchXRD
	}
}
