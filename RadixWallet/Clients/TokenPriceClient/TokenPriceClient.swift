// MARK: - TokenPriceClient
public struct TokenPriceClient: Sendable, DependencyKey {
	public let getTokenPrices: GetTokenPrices
}

extension TokenPriceClient {
	public struct FetchPricesRequest: Encodable {
		public let tokens: [ResourceAddress]
		public let lsus: [ResourceAddress]
		public let currency: FiatCurrency = .usd
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
		let rootURL = URL(string: "https://token-price.extratools.works")!

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
			return try .init(
				jsonDecoder().decode(TokensPriceResponse.self, from: data),
				currency: fetchRequest.currency
			)
		}

		//        @Sendable
		//        func fetchTokenPrices() async throws -> TokenPrices {
		//            let tokensURL = rootURL.appending(component: "tokens")
		//            var request = URLRequest(url: tokensURL)
		//            request.httpMethod = "POST"
//
		//            let data = try await httpClient.executeRequest(request)
		//            let decoded = try jsonDecoder().decode([FailableDecodable<TokenPrice>].self, from: data)
		//            return Set(decoded.compactMap { try? $0.result.get() })
		//        }

		return .init(
			getTokenPrices: { request in
				try await cacheClient.withCaching(cacheEntry: .tokenPrices, request: {
					try await getTokenPrices(request)
				})
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

// MARK: - TokenPrices
public struct TokenPrices: Sendable, Codable {
	public let tokens: IdentifiedArrayOf<TokenPrice>
	public let lsus: IdentifiedArrayOf<LSUPrice>
}

extension TokenPrices {
	public struct CurrencyPrice: Sendable, Codable {
		public let price: Double
		public let currency: FiatCurrency
	}

	public struct TokenPrice: Identifiable, Sendable, Codable {
		public var id: ResourceAddress {
			resourceAddress
		}

		public let resourceAddress: ResourceAddress
		public let price: CurrencyPrice
	}

	public struct LSUPrice: Identifiable, Sendable, Codable {
		public var id: ResourceAddress {
			resourceAddress
		}

		public let resourceAddress: ResourceAddress
		public let xrdRedemptionValue: RETDecimal
		public let price: CurrencyPrice
	}
}

extension TokenPrices {
	init(_ tokenPricesResponse: TokensPriceResponse, currency: FiatCurrency) throws {
		self.tokens = try tokenPricesResponse.tokens.map {
			try TokenPrice($0, currency: currency)
		}.asIdentifiable()

		self.lsus = try tokenPricesResponse.lsus.map {
			try LSUPrice($0, currency: currency)
		}.asIdentifiable()
	}
}

extension TokenPrices.TokenPrice {
	init(_ rawTokenPrice: TokensPriceResponse.TokenPrice, currency: FiatCurrency) throws {
		self.resourceAddress = try .init(validatingAddress: rawTokenPrice.resourceAddress)
		self.price = .init(price: rawTokenPrice.price, currency: currency)
	}
}

extension TokenPrices.LSUPrice {
	init(_ rawLSUPrice: TokensPriceResponse.LSUPrice, currency: FiatCurrency) throws {
		self.resourceAddress = try .init(validatingAddress: rawLSUPrice.resourceAddress)
		self.xrdRedemptionValue = try rawLSUPrice.xrdRedemptionValue.asRETDecimal()
		self.price = .init(price: rawLSUPrice.price, currency: currency)
	}
}

// MARK: - TokensPriceResponse
public struct TokensPriceResponse: Decodable {
	public let tokens: [TokenPrice]
	public let lsus: [LSUPrice]
}

extension TokensPriceResponse {
	public struct TokenPrice: Decodable {
		enum CodingKeys: String, CodingKey {
			case resourceAddress = "resource_address"
			case price = "usd_price"
		}

		public let resourceAddress: String
		public let price: Double
	}

	public struct LSUPrice: Decodable {
		enum CodingKeys: String, CodingKey {
			case resourceAddress = "resource_address"
			case xrdRedemptionValue = "xrd_redemption_value"
			case price = "usd_price"
		}

		public let resourceAddress: String
		public let xrdRedemptionValue: Double
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
