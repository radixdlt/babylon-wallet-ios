import ClientPrelude
import Foundation
import SharedModels

// MARK: - AccountPortfoliosClient
public struct AccountPortfoliosClient: Sendable {
	/// Fetches the account portfolios for the given addresses.
	///
	/// Will return the portfolios after fetch, as well will notify any subscribes through `portfolioForAccount`
	public var fetchAccountPortfolios: FetchAccountPortfolios

	/// Fetches the account portfolio for the given address.
	///
	/// Will return the portfolio after fetch, as well will notify any subscribes through `portfolioForAccount`
	public var fetchAccountPortfolio: FetchAccountPortfolio

	/// Subscribe to portfolio changes for a given account address
	public var portfolioForAccount: PortfolioForAccount

	public var portfolios: Portfolios
}

extension AccountPortfoliosClient {
	public typealias FetchAccountPortfolio = @Sendable (_ address: AccountAddress, _ refresh: Bool) async throws -> AccountPortfolio
	public typealias FetchAccountPortfolios = @Sendable (_ address: [AccountAddress], _ refresh: Bool) async throws -> [AccountPortfolio]
	public typealias PortfolioForAccount = @Sendable (_ address: AccountAddress) async -> AnyAsyncSequence<AccountPortfolio>
	public typealias Portfolios = @Sendable () -> [AccountPortfolio]
}

extension DependencyValues {
	public var accountPortfoliosClient: AccountPortfoliosClient {
		get { self[AccountPortfoliosClient.self] }
		set { self[AccountPortfoliosClient.self] = newValue }
	}
}
