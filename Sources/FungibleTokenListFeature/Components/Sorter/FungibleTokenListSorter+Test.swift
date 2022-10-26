#if DEBUG
import Asset
import ComposableArchitecture
import XCTestDynamicOverlay

extension FungibleTokenListSorter: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		sortTokens: XCTUnimplemented("\(Self.self).sortTokens")
	)
}

public extension FungibleTokenListSorter {
	static let noop = Self(
		sortTokens: { _ in [] }
	)
}

#endif
