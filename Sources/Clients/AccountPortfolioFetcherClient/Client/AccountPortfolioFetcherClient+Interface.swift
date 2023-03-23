import ClientPrelude
import struct Profile.AccountAddress // FIXME: should probably be in ProfileModels so we can remove this import altogether

// MARK: - AccountPortfolioFetcherClient
public struct AccountPortfolioFetcherClient: Sendable {
	public var fetchPortfolioForAccount: FetchPortfolioForAccount
	public var fetchPortfolioForAccounts: FetchPortfolioForAccounts

	public init(
		fetchPortfolioForAccount: @escaping FetchPortfolioForAccount,
		fetchPortfolioForAccounts: @escaping FetchPortfolioForAccounts
	) {
		self.fetchPortfolioForAccount = fetchPortfolioForAccount
		self.fetchPortfolioForAccounts = fetchPortfolioForAccounts
	}
}

extension AccountPortfolioFetcherClient {
	public typealias FetchPortfolioForAccount = @Sendable (AccountAddress, Bool) async throws -> AccountPortfolio
	public typealias FetchPortfolioForAccounts = @Sendable (IdentifiedArrayOf<AccountAddress>, Bool) async throws -> IdentifiedArrayOf<AccountPortfolio>
}

extension DependencyValues {
	public var accountPortfolioFetcherClient: AccountPortfolioFetcherClient {
		get { self[AccountPortfolioFetcherClient.self] }
		set { self[AccountPortfolioFetcherClient.self] = newValue }
	}
}
