// MARK: - TokenPricesClient
public struct TokenPricesClient: Sendable, DependencyKey {
	public let getTokenPrices: GetTokenPrices
}

extension TokenPricesClient {
	public typealias TokenPrices = [ResourceAddress: RETDecimal]
	public struct FetchPricesRequest: Encodable {
		public let tokens: [ResourceAddress]
		public let currency: FiatCurrency
	}

	public typealias GetTokenPrices = @Sendable (FetchPricesRequest) async throws -> TokenPrices
}
