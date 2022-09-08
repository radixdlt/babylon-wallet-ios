import Common

// MARK: - TokenWorthFetcher
public struct TokenWorthFetcher {
	public var fetchWorth: FetchWorth
	public var fetchSingleTokenWorth: FetchSingleTokenWorth

	public init(
		fetchWorth: @escaping FetchWorth,
		fetchSingleTokenWorth: @escaping FetchSingleTokenWorth
	) {
		self.fetchWorth = fetchWorth
		self.fetchSingleTokenWorth = fetchSingleTokenWorth
	}
}

// MARK: - Typealias
public extension TokenWorthFetcher {
	typealias FetchWorth = @Sendable ([Token], FiatCurrency) async throws -> [TokenWorthContainer]
	typealias FetchSingleTokenWorth = @Sendable (Token, FiatCurrency) async throws -> Float?
}
