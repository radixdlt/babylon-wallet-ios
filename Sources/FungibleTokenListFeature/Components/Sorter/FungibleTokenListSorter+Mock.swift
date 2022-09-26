#if DEBUG
import Asset
import XCTestDynamicOverlay

public extension FungibleTokenListSorter {
	static let mock = Self(
		sortTokens: { _ in
			[FungibleTokenCategory(type: .xrd, tokenContainers: [])]
		}
	)

	static let unimplemented = Self(
		sortTokens: XCTUnimplemented("\(Self.self).sortTokens")
	)
}
#endif
