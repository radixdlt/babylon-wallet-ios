import ClientPrelude
import struct Profile.AccountAddress // FIXME: should probably be in ProfileModels so we can remove this import altogether

// MARK: - AccountPortfolioFetcherClient
public struct AccountPortfolioFetcherClient: Sendable {
	public var fetchPortfolioForAccount: FetchPortfolioForAccount
	public var fetchPortfolioForAccounts: FetchPortfolioForAccounts
        public var fetchFungibleTokens: FetchFungibleTokens

	public init(
		fetchPortfolioForAccount: @escaping FetchPortfolioForAccount,
		fetchPortfolioForAccounts: @escaping FetchPortfolioForAccounts,
                fetchFungibleTokens: @escaping FetchFungibleTokens
	) {
		self.fetchPortfolioForAccount = fetchPortfolioForAccount
		self.fetchPortfolioForAccounts = fetchPortfolioForAccounts
                self.fetchFungibleTokens = fetchFungibleTokens
	}
}

extension AccountPortfolioFetcherClient {
        public struct FungibleTokensPageResponse: Sendable, Equatable {
                public let tokens: [FungibleTokenContainer]
                public let nextPageCursor: String?
        }

	public typealias FetchPortfolioForAccounts = @Sendable ([AccountAddress]) async throws -> IdentifiedArrayOf<AccountPortfolio>
	public typealias FetchPortfolioForAccount = @Sendable (AccountAddress) async throws -> AccountPortfolio
        public typealias FetchFungibleTokens = @Sendable (AccountAddress, _ nextPageCursor: String) async throws -> FungibleTokensPageResponse
}

extension DependencyValues {
	public var accountPortfolioFetcherClient: AccountPortfolioFetcherClient {
		get { self[AccountPortfolioFetcherClient.self] }
		set { self[AccountPortfolioFetcherClient.self] = newValue }
	}
}

extension AccountPortfolioFetcherClient {
	public func fetchPortfolioFor(accounts: Profile.Network.Accounts) async throws -> IdentifiedArrayOf<AccountPortfolio> {
		try await fetchPortfolioFor(accounts: accounts.rawValue)
	}

	public func fetchPortfolioFor(accounts: IdentifiedArrayOf<Profile.Network.Account>) async throws -> IdentifiedArrayOf<AccountPortfolio> {
		try await fetchPortfolioForAccounts(accounts.map(\.address))
	}

	public func fetchPortfolioFor(account: Profile.Network.Account) async throws -> AccountPortfolio {
		try await fetchPortfolioForAccount(account.address)
	}
}
