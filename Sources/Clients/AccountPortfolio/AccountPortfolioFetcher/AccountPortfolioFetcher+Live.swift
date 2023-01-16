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

public extension AccountPortfolioFetcher {
	/// Returns an array of FungibleTokenContainers containing XRD.
	func fetchXRDBalance(for accountAddresses: [AccountAddress], on networkID: NetworkID) async throws -> [FungibleTokenContainer] {
		let accountPortfolioDictionary = try await fetchPortfolio(accountAddresses)
		return accountPortfolioDictionary.values
			.map(\.fungibleTokenContainers)
			.flatMap(\.elements)
			.filter { $0.asset.isXRD(on: networkID) }
	}

	/// Returns an AccountAddress with enough funds for a given lock fee.
	func firstAccountWithEnoughXRDForLockFee(xrdContainers: [FungibleTokenContainer], lockFee: Int) -> AccountAddress? {
		let container = xrdContainers.first { container in
			if let amount = container.amount,
			   let value = Float(amount),
			   value >= Float(lockFee)
			{
				return true
			}
			return false
		}
		return container?.owner
	}
}
