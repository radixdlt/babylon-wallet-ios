import Asset
import Dependencies
import XCTestDynamicOverlay

// MARK: - AssetFetcher + TestDependencyKey
extension AssetFetcher: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		fetchAssets: unimplemented("\(Self.self).fetchAssets")
	)
}

public extension AssetFetcher {
	static let noop = Self(
		fetchAssets: { _ in
			AccountPortfolio(fungibleTokenContainers: [], nonFungibleTokenContainers: [], poolShareContainers: [], badgeContainers: [])
		}
	)
}
