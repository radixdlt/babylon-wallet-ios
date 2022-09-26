import Asset

public extension AssetUpdater {
	static let mock = Self(
		updateAssets: { _, _ in
			AccountPortfolio.empty
		}, updateSingleAsset: { asset, _ in
			if let asset = asset as? FungibleToken {
				return FungibleTokenContainer(asset: asset, amount: nil, worth: nil)
			} else if let asset = asset as? NonFungibleToken {
				return NonFungibleTokenContainer(asset: asset, metadata: nil)
			} else if let asset = asset as? PoolShare {
				return PoolShareContainer(asset: asset, metadata: nil)
			} else if let asset = asset as? Badge {
				return BadgeContainer(asset: asset, metadata: nil)
			} else {
				fatalError("Unknown asset type")
			}
		}
	)
}
