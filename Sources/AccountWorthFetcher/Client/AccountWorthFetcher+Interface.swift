import Address

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
	typealias AccountsWorth = [Address: AccountPortfolioWorth]
	typealias FetchWorth = @Sendable ([Address]) async throws -> AccountsWorth
}
