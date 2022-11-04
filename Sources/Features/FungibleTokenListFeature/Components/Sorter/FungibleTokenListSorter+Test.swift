#if DEBUG
import Asset
import Dependencies
import XCTestDynamicOverlay

extension FungibleTokenListSorter: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		sortTokens: unimplemented("\(Self.self).sortTokens")
	)
}

public extension FungibleTokenListSorter {
	static let noop = Self(
		sortTokens: { _ in [] }
	)
}

#endif
