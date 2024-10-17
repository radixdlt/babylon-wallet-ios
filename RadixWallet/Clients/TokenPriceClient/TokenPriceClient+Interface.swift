// MARK: - TokenPricesClient
struct TokenPricesClient: Sendable, DependencyKey {
	let getTokenPrices: GetTokenPrices
}

extension TokenPricesClient {
	typealias TokenPrices = [ResourceAddress: Decimal192]
	struct FetchPricesRequest: Encodable {
		let tokens: [ResourceAddress]
		let currency: FiatCurrency
	}

	typealias GetTokenPrices = @Sendable (FetchPricesRequest, _ refresh: Bool) async throws -> TokenPrices
}
