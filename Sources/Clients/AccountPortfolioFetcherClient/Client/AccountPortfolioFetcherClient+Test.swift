import ClientPrelude

// MARK: - AccountPortfolioFetcherClient + TestDependencyKey
extension AccountPortfolioFetcherClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		fetchPortfolioForAccount: unimplemented("\(Self.self).fetchPortfolioForAccount"),
		fetchPortfolioForAccounts: unimplemented("\(Self.self).fetchPortfolioForAccounts")
	)
}

extension AccountPortfolioFetcherClient {
	public static let noop = Self(
		fetchPortfolioForAccount: { _, _ in throw NoopError() },
		fetchPortfolioForAccounts: { _, _ in throw NoopError() }
	)
}
