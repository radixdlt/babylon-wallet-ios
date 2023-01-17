import ClientPrelude
import struct Profile.AccountAddress // FIXME: should probably be in ProfileModels so we can remove this import altogether

// MARK: - AccountPortfolioFetcher
public struct AccountPortfolioFetcher: Sendable {
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
