import Profile

// MARK: - AccountWorthFetcher
public struct AccountWorthFetcher {
	public var fetchWorth: FetchWorth

	public init(
		fetchWorth: @escaping FetchWorth
	) {
		self.fetchWorth = fetchWorth
	}
}

// MARK: - Typealias
public extension AccountWorthFetcher {
	typealias AccountsWorth = [Profile.Account.Address: AccountPortfolioWorth]
	typealias FetchWorth = @Sendable ([Profile.Account.Address]) async throws -> AccountsWorth
}
