import ClientPrelude
import Foundation
import SharedModels

// MARK: - AccountPortfoliosClient
public actor AccountPortfoliosClient {
	public var fetchAccountPortfolios: FetchAccountPortfolios
	public var fetchAccountPortfolio: FetchAccountPortfolio
	public var portfolioForAccount: PortfolioForAccount

	public let portfolios: AsyncCurrentValueSubject<Set<AccountPortfolio>>

	internal init(fetchAccountPortfolios: @escaping FetchAccountPortfolios,
	              fetchAccountPortfolio: @escaping FetchAccountPortfolio,
	              portfolioForAccount: @escaping PortfolioForAccount,
	              portfolios: AsyncCurrentValueSubject<Set<AccountPortfolio>>)
	{
		self.fetchAccountPortfolios = fetchAccountPortfolios
		self.fetchAccountPortfolio = fetchAccountPortfolio
		self.portfolioForAccount = portfolioForAccount
		self.portfolios = portfolios
	}
}

extension AccountPortfoliosClient {
	public typealias FetchAccountPortfolios = @Sendable (_ addresses: [AccountAddress]) async throws -> [AccountPortfolio]
	public typealias FetchAccountPortfolio = @Sendable (_ address: AccountAddress, _ refresh: Bool) async throws -> AccountPortfolio
	public typealias PortfolioForAccount = @Sendable (_ address: AccountAddress) -> AnyAsyncSequence<AccountPortfolio>
}

extension DependencyValues {
	public var accountPortfoliosClient: AccountPortfoliosClient {
		get { self[AccountPortfoliosClient.self] }
		set { self[AccountPortfoliosClient.self] = newValue }
	}
}
