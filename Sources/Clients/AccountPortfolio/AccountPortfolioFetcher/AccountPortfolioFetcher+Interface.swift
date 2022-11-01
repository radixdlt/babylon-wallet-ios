import Dependencies
import Profile

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
	typealias FetchPortfolio = @Sendable ([AccountAddress]) async throws -> AccountPortfolioDictionary
}

public extension DependencyValues {
	var accountPortfolioFetcher: AccountPortfolioFetcher {
		get { self[AccountPortfolioFetcher.self] }
		set { self[AccountPortfolioFetcher.self] = newValue }
	}
}
