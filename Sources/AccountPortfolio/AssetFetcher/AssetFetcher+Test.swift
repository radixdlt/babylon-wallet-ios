#if DEBUG
import Asset
import ComposableArchitecture
import XCTestDynamicOverlay

extension AssetFetcher: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		fetchAssets: XCTUnimplemented("\(Self.self).fetchAssets")
	)
}

public extension AssetFetcher {
	static let noop = Self(
		fetchAssets: { _ in
			OwnedAssets(ownedFungibleTokens: [], ownedNonFungibleTokens: [])
		}
	)
}
#endif
