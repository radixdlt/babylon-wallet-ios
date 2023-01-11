import Prelude

// MARK: - AccountPortfolioFetcher + TestDependencyKey
extension AccountPortfolioFetcher: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		fetchPortfolio: unimplemented("\(Self.self).fetchPortfolio")
	)
}

public extension AccountPortfolioFetcher {
	static let noop = Self(
		fetchPortfolio: { _ in [:] }
	)
}
