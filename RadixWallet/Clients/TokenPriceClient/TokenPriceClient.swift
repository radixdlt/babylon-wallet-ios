// MARK: - TokenPriceClient
public struct TokenPriceClient: Sendable, DependencyKey {
	public let getTokenPrices: GetTokenPrices
}

extension TokenPriceClient {
	public typealias TokenPrices = [ResourceAddress: RETDecimal]
	public struct FetchPricesRequest: Encodable {
		public let tokens: [ResourceAddress]
		public let currency: FiatCurrency
	}

	public typealias GetTokenPrices = @Sendable (FetchPricesRequest) async throws -> TokenPrices
}

private extension NumberFormatter {
	static let RETDecialCompatibleFormatter: NumberFormatter = {
		let formatter = NumberFormatter()
		formatter.numberStyle = .decimal
		formatter.maximumFractionDigits = Int(RETDecimal.maxDivisibility)

		return formatter
	}()
}

extension Double {
	func asRETDecimal() throws -> RETDecimal {
		guard let formatted = NumberFormatter.RETDecialCompatibleFormatter.string(for: self) else {
			struct InvalidDoubleError: Error {}
			throw InvalidDoubleError()
		}
		return try RETDecimal(formattedString: formatted)
	}
}

extension TokenPriceClient {
	public static let liveValue: TokenPriceClient = {
		@Dependency(\.httpClient) var httpClient
		@Dependency(\.jsonDecoder) var jsonDecoder
		@Dependency(\.jsonEncoder) var jsonEncoder
		@Dependency(\.cacheClient) var cacheClient
		let rootURL = URL(string: "https://dev-token-price.extratools.works")!

		@Sendable
		func getTokenPrices(_ fetchRequest: FetchPricesRequest) async throws -> TokenPrices {
			let pricesEndpoint = rootURL.appending(component: "price").appending(component: "tokens")
			var urlRequest = URLRequest(url: pricesEndpoint)
			urlRequest.httpMethod = "POST"
			urlRequest.httpBody = try jsonEncoder().encode(fetchRequest)

			urlRequest.allHTTPHeaderFields = [
				"accept": "application/json",
				"Content-Type": "application/json",
			]

			let data = try await httpClient.executeRequest(urlRequest)
			let decodedResponse = try jsonDecoder().decode(TokensPriceResponse.self, from: data)
			return .init(decodedResponse)
		}

		return .init(
			getTokenPrices: { request in
				try await cacheClient.withCaching(
					cacheEntry: .tokenPrices(request.currency),
					invalidateCached: {
						Array($0.keys) != request.tokens ? .cachedIsInvalid : .cachedIsValid
					},
					request: { try await getTokenPrices(request) }
				)
			}
		)
	}()
}

extension DependencyValues {
	public var tokenPriceClient: TokenPriceClient {
		get { self[TokenPriceClient.self] }
		set { self[TokenPriceClient.self] = newValue }
	}
}

extension TokenPriceClient.TokenPrices {
	init(_ tokenPricesResponse: TokensPriceResponse) {
		self = tokenPricesResponse.tokens.reduce(into: [:]) { partialResult, next in
			let roundedToRETPrecision = next.price.roundDoubleToDecimalPlaces(Int(RETDecimal.maxDivisibility - 10))
			partialResult[next.resourceAddress] = RETDecimal(floatLiteral: roundedToRETPrecision)
		}
	}
}

extension Double {
	func roundDoubleToDecimalPlaces(_ decimalPlaces: Int) -> Double {
		var decimalValue = Decimal(self)
		var result = Decimal()
		NSDecimalRound(&result, &decimalValue, decimalPlaces, .plain)
		return (result as NSDecimalNumber).doubleValue
	}
}

// MARK: - TokensPriceResponse
public struct TokensPriceResponse: Decodable {
	public let tokens: [TokenPrice]
}

// MARK: TokensPriceResponse.TokenPrice
extension TokensPriceResponse {
	public struct TokenPrice: Decodable {
		enum CodingKeys: String, CodingKey {
			case resourceAddress = "resource_address"
			case price = "usd_price"
		}

		public let resourceAddress: ResourceAddress
		public let price: Double
	}
}

// MARK: - FailableDecodable
struct FailableDecodable<T: Decodable>: Decodable {
	let result: Result<T, Error>

	init(from decoder: Decoder) throws {
		result = Result(catching: { try T(from: decoder) })
	}
}
