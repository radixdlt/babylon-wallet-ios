import ClientPrelude
import Foundation
import SharedModels

// MARK: - AccountPortfoliosClient
public actor AccountPortfoliosClient {
	public var fetchAccountPortfolio: FetchAccountPortfolio
	public var portfolioForAccount: PortfolioForAccount

	internal init(
		fetchAccountPortfolio: @escaping FetchAccountPortfolio,
		portfolioForAccount: @escaping PortfolioForAccount
	) {
		self.fetchAccountPortfolio = fetchAccountPortfolio
		self.portfolioForAccount = portfolioForAccount
	}
}

extension AccountPortfoliosClient {
	public typealias FetchAccountPortfolio = @Sendable (_ address: AccountAddress, _ refresh: Bool) async throws -> AccountPortfolio
	public typealias PortfolioForAccount = @Sendable (_ address: AccountAddress) async -> AnyAsyncSequence<AccountPortfolio>
}

extension DependencyValues {
	public var accountPortfoliosClient: AccountPortfoliosClient {
		get { self[AccountPortfoliosClient.self] }
		set { self[AccountPortfoliosClient.self] = newValue }
	}
}
