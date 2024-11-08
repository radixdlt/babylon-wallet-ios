
extension AccountPortfoliosClient: TestDependencyKey {
	static let previewValue = AccountPortfoliosClient.noop

	static let testValue = AccountPortfoliosClient(
		fetchAccountPortfolios: unimplemented("\(AccountPortfoliosClient.self).fetchAccountPortfolios"),
		fetchAccountPortfolio: unimplemented("\(AccountPortfoliosClient.self).fetchAccountPortfolio"),
		portfolioUpdates: unimplemented("\(AccountPortfoliosClient.self).fetchAccountPortfolio"),
		portfolioForAccount: unimplemented("\(AccountPortfoliosClient.self).portfolioForAccount"),
		portfolios: unimplemented("\(AccountPortfoliosClient.self).portfolios")
	)

	static let noop = AccountPortfoliosClient(
		fetchAccountPortfolios: { _, _ in throw NoopError() },
		fetchAccountPortfolio: { _, _ in throw NoopError() },
		portfolioUpdates: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		portfolioForAccount: { _ in fatalError() },
		portfolios: { fatalError() }
	)
}
