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
extension AccountPortfolioFetcher {
	public typealias FetchPortfolio = @Sendable ([AccountAddress]) async throws -> AccountPortfolioDictionary
}

extension DependencyValues {
	public var accountPortfolioFetcher: AccountPortfolioFetcher {
		get { self[AccountPortfolioFetcher.self] }
		set { self[AccountPortfolioFetcher.self] = newValue }
	}
}
