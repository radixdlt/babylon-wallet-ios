import Address

// MARK: - AccountPortfolioFetcher
public struct AccountPortfolioFetcher {
	public var fetchPortfolio: FetchPortfolio

	public init(
		fetchPortfolio: @escaping FetchPortfolio
	) {
		self.fetchPortfolio = fetchPortfolio
	}
}

// MARK: AccountPortfolioFetcher.FetchPortfolio
public extension AccountPortfolioFetcher {
	typealias FetchPortfolio = @Sendable ([Address]) async throws -> AccountPortfolioDictionary
}
