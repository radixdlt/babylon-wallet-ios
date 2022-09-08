import Profile

// MARK: - TokenFetcher
public struct TokenFetcher {
	public var fetchTokens: FetchTokens

	public init(
		fetchTokens: @escaping FetchTokens
	) {
		self.fetchTokens = fetchTokens
	}
}

// MARK: - Typealias
public extension TokenFetcher {
	typealias FetchTokens = @Sendable (Profile.Account.Address) async throws -> [Token]
}
