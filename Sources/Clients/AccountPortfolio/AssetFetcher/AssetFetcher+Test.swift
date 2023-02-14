import ClientPrelude

// MARK: - AssetFetcher + TestDependencyKey
extension AssetFetcher: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		fetchAssets: unimplemented("\(Self.self).fetchAssets")
	)
}

extension AssetFetcher {
	public static let noop = Self(
		fetchAssets: { _ in
			AccountPortfolio(fungibleTokenContainers: [], nonFungibleTokenContainers: [], poolShareContainers: [], badgeContainers: [])
		}
	)
}
