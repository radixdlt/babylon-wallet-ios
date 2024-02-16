
extension AccountPortfoliosClient: TestDependencyKey {
	public static let previewValue = AccountPortfoliosClient.noop

	public static let testValue = AccountPortfoliosClient(
		fetchAccountPortfolios: unimplemented("\(AccountPortfoliosClient.self).fetchAccountPortfolios"),
		fetchAccountPortfolio: unimplemented("\(AccountPortfoliosClient.self).fetchAccountPortfolio"),
		portfolioForAccount: unimplemented("\(AccountPortfoliosClient.self).portfolioForAccount"),
		portfoliosUpdates: unimplemented("\(AccountPortfoliosClient.self).portfoliosUpdates"),
		portfolios: unimplemented("\(AccountPortfoliosClient.self).portfolios")
	)

	public static let noop = AccountPortfoliosClient(
		fetchAccountPortfolios: { _, _ in throw NoopError() },
		fetchAccountPortfolio: { _, _ in throw NoopError() },
		portfolioForAccount: { _ in fatalError() },
		portfoliosUpdates: { fatalError() },
		portfolios: { fatalError() }
	)
}
