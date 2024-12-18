
extension AccountPortfoliosClient: TestDependencyKey {
	static let previewValue = AccountPortfoliosClient.noop

	static let testValue = AccountPortfoliosClient(
		fetchAccountPortfolios: unimplemented("\(AccountPortfoliosClient.self).fetchAccountPortfolios"),
		fetchAccountPortfolio: unimplemented("\(AccountPortfoliosClient.self).fetchAccountPortfolio"),
		portfolioUpdates: unimplemented("\(AccountPortfoliosClient.self).portfolioUpdates", placeholder: noop.portfolioUpdates),
		portfolioForAccount: unimplemented("\(AccountPortfoliosClient.self).portfolioForAccount", placeholder: noop.portfolioForAccount),
		portfolios: unimplemented("\(AccountPortfoliosClient.self).portfolios", placeholder: noop.portfolios),
		syncAccountsDeletedOnLedger: unimplemented("\(AccountPortfoliosClient.self).syncAccountsDeletedOnLedger")
	)

	static let noop = AccountPortfoliosClient(
		fetchAccountPortfolios: { _, _ in throw NoopError() },
		fetchAccountPortfolio: { _, _ in throw NoopError() },
		portfolioUpdates: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		portfolioForAccount: { _ in fatalError() },
		portfolios: { fatalError() },
		syncAccountsDeletedOnLedger: {}
	)
}
