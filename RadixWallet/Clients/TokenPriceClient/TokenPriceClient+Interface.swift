// MARK: - TokenPricesClient
public struct TokenPricesClient: Sendable, DependencyKey {
	public let getTokenPrices: GetTokenPrices
}

extension TokenPricesClient {
	public typealias TokenPrices = [ResourceAddress: Decimal192]
	public struct FetchPricesRequest: Encodable {
		public let tokens: [ResourceAddress]
		public let currency: FiatCurrency
	}

	public typealias GetTokenPrices = @Sendable (FetchPricesRequest, _ refresh: Bool) async throws -> TokenPrices
}
