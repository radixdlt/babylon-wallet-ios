import Foundation

public extension AssetFetcher {
	static let mock = Self(
		fetchAssets: { _ in
			OwnedAssets(ownedFungibleTokens: [], ownedNonFungibleTokens: [])
		}
	)
}
