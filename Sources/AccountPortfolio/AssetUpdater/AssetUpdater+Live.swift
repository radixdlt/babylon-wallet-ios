import AppSettings
import Asset
import Profile

public extension AssetUpdater {
	static let live: Self = {
		let updateSingleAsset: UpdateSingleAsset = { asset, _ in
			if let asset = asset as? FungibleToken {
				// TODO: fetch real amount and worth when API is ready
				let random = Float.random(in: 0 ... 10000)
				return FungibleTokenContainer(asset: asset, amount: random, worth: random)

			} else if let asset = asset as? NonFungibleToken {
				// TODO: fetch real metadata when API is ready
				let metadata = [
					["Principle amount": "2,000"],
					["Principle": "XDR"],
					["Term (months)": "12"],
					["Rate (%)": "0.35"],
				]

				return NonFungibleTokenContainer(asset: asset, metadata: metadata)

			} else if let asset = asset as? PoolShare {
				// TODO: fetch real metadata when API is ready
				return PoolShareContainer(asset: asset, metadata: nil)

			} else if let asset = asset as? Badge {
				// TODO: fetch real metadata when API is ready
				return BadgeContainer(asset: asset, metadata: nil)

			} else {
				fatalError("Unknown asset type")
			}
		}

		return Self(
			updateAssets: { assetsGroup, currency in
				try await withThrowingTaskGroup(
					of: (any AssetContainer).self,
					returning: AccountPortfolio.self,
					body: { taskGroup in
						for group in assetsGroup {
							for asset in group {
								taskGroup.addTask {
									let assetContainer = try await updateSingleAsset(asset, currency)
									return assetContainer
								}
							}
						}

						var updatedAssetContainers = [any AssetContainer]()
						for try await result in taskGroup {
							updatedAssetContainers.append(result)
						}

						var fungibleTokenContainers = [FungibleTokenContainer]()
						var nftContainers = [NonFungibleTokenContainer]()
						var poolShareContainers = [PoolShareContainer]()
						var badgeContainers = [BadgeContainer]()

						for container in updatedAssetContainers {
							if let container = container as? FungibleTokenContainer {
								fungibleTokenContainers.append(container)

							} else if let container = container as? NonFungibleTokenContainer {
								nftContainers.append(container)

							} else if let container = container as? PoolShareContainer {
								poolShareContainers.append(container)

							} else if let container = container as? BadgeContainer {
								badgeContainers.append(container)

							} else {
								fatalError("Unknown asset container type")
							}
						}

						return AccountPortfolio(
							fungibleTokenContainers: fungibleTokenContainers,
							nonFungibleTokenContainers: nftContainers,
							poolShareContainers: poolShareContainers,
							badgeContainers: badgeContainers
						)
					}
				)

			}, updateSingleAsset: updateSingleAsset
		)
	}()
}
