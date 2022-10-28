#if DEBUG
import Dependencies
import XCTestDynamicOverlay

extension AccountPortfolioFetcher: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		fetchPortfolio: XCTUnimplemented("\(Self.self).fetchPortfolio")
	)
}

public extension AccountPortfolioFetcher {
	static let noop = Self(
		fetchPortfolio: { _ in [:] }
	)
}
#endif
