import Address

// MARK: - TokenFetcher
public struct TokenFetcher {
	public var fetchTokens: FetchTokens

	public init(
		fetchTokens: @escaping FetchTokens
	) {
		self.fetchTokens = fetchTokens
	}
}

// MARK: TokenFetcher.FetchTokens
public extension TokenFetcher {
	typealias FetchTokens = @Sendable (Address) async throws -> [Token]
}
