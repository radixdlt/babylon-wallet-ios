// MARK: - TokenPriceClient
public struct TokenPriceClient: Sendable, DependencyKey {
	public let loadTokenPrices: LoadTokenPrices
	public let getPriceForToken: GetPriceForToken
}

extension TokenPriceClient {
	public typealias LoadTokenPrices = @Sendable () async throws -> Void
	public typealias GetPriceForToken = @Sendable (ResourceAddress) -> RETDecimal?
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
		typealias TokenPrices = [FiatCurrency: [ResourceAddress: RETDecimal]]

		actor State {
			var tokenPrices: TokenPrices = [:]
			var selectedCurrency: FiatCurrency = .usd

			func setTokenPrices(_ tokenPrices: TokenPrices) {
				self.tokenPrices = tokenPrices
			}

			func getPrice(_ address: ResourceAddress) -> RETDecimal {
				tokenPrices[selectedCurrency]?[address]
			}
		}

		let state = State()

		@Dependency(\.httpClient) var httpClient
		@Dependency(\.jsonDecoder) var jsonDecoder
		@Dependency(\.jsonEncoder) var jsonEncoder
		@Dependency(\.cacheClient) var cacheClient
		let rootURL = URL(string: "https://dev-token-price.extratools.works")!

		@Sendable
		func fetchTokenPrices() async throws {
			let tokensURL = rootURL.appending(component: "tokens")
			var request = URLRequest(url: tokensURL)
			request.httpMethod = "POST"

			let data = try await httpClient.executeRequest(request)
			let decoded = try jsonDecoder().decode([FailableDecodable<TokenPriceResponse>].self, from: data)
			let prices = Set(decoded.compactMap { try? $0.result.get() })
			var pp = TokenPrices()
			for price in prices {
				pp[price.currency, default: [:]][price.resourceAddress] = RETDecimal(floatLiteral: price.price)
			}
			await state.setTokenPrices(pp)
		}

		return .init(
			loadTokenPrices: {},
			getPriceForToken: { _ in
				nil
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

// MARK: - TokenPriceResponse
struct TokenPriceResponse: Decodable, Hashable {
	let resourceAddress: ResourceAddress
	let price: Double
	let currency: FiatCurrency
}

// MARK: - FailableDecodable
struct FailableDecodable<T: Decodable>: Decodable {
	let result: Result<T, Error>

	init(from decoder: Decoder) throws {
		result = Result(catching: { try T(from: decoder) })
	}
}
