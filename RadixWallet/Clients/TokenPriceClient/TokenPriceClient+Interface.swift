import Sargon

// MARK: - TokenPricesClient
struct TokenPricesClient: DependencyKey {
	let getTokenPrices: GetTokenPrices
	let getTokenPriceServices: GetTokenPriceServices
	let addTokenPriceService: AddTokenPriceService
	let deleteTokenPriceService: DeleteTokenPriceService
}

extension TokenPricesClient {
	typealias TokenPrices = [ResourceAddress: Decimal192]
	struct FetchPricesRequest: Encodable {
		let tokens: [ResourceAddress]
		let currency: FiatCurrency
	}

	typealias GetTokenPrices = @Sendable (FetchPricesRequest, _ refresh: Bool) async throws -> TokenPrices
	typealias GetTokenPriceServices = @Sendable () throws -> [TokenPriceService]
	typealias AddTokenPriceService = @Sendable (URL) async throws -> Bool
	typealias DeleteTokenPriceService = @Sendable (URL) async throws -> Bool
}
