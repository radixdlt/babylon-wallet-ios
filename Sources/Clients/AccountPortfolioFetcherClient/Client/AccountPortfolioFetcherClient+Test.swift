import ClientPrelude

// MARK: - AccountPortfolioFetcherClient + TestDependencyKey
extension AccountPortfolioFetcherClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		fetchPortfolioForAccount: unimplemented("\(Self.self).fetchPortfolioForAccount"),
                fetchPortfolioForAccounts: unimplemented("\(Self.self).fetchPortfolioForAccounts"),
                fetchFungibleTokens: unimplemented("\(Self.self).fetchFungibleTokens")
	)
}

extension AccountPortfolioFetcherClient {
	public static let noop = Self(
		fetchPortfolioForAccount: { _ in throw NoopError() },
                fetchPortfolioForAccounts: { _ in throw NoopError() },
                fetchFungibleTokens: { _, _ in throw NoopError() }
	)
}
