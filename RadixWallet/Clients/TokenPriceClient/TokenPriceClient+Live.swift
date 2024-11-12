extension TokenPricesClient {
	static let liveValue: TokenPricesClient = {
		@Dependency(\.httpClient) var httpClient
		@Dependency(\.jsonDecoder) var jsonDecoder
		@Dependency(\.jsonEncoder) var jsonEncoder
		@Dependency(\.cacheClient) var cacheClient

		let rootURL = URL(string: "https://token-price-service.radixdlt.com")!

		@Sendable
		func getTokenPrices(_ fetchRequest: FetchPricesRequest) async throws -> TokenPrices {
			let pricesEndpoint = rootURL.appending(component: "price").appending(component: "tokens")
			var urlRequest = URLRequest(url: pricesEndpoint)
			urlRequest.httpMethod = "POST"
			urlRequest.httpBody = try jsonEncoder().encode(fetchRequest)
			urlRequest.setHttpHeaderFields()

			let data = try await httpClient.executeRequest(urlRequest)
			let decodedResponse = try jsonDecoder().decode(TokensPriceResponse.self, from: data)
			return .init(decodedResponse)
		}

		return .init(
			getTokenPrices: { request, refresh in
				try await cacheClient.withCaching(
					cacheEntry: .tokenPrices(request.currency),
					forceRefresh: refresh,
					invalidateCached: {
						Array($0.keys) != request.tokens ? .cachedIsInvalid : .cachedIsValid
					},
					request: { try await getTokenPrices(request) }
				)
			}
		)
	}()
}

extension TokenPricesClient.TokenPrices {
	init(_ tokenPricesResponse: TokensPriceResponse) {
		self = tokenPricesResponse.tokens.reduce(into: [:]) { partialResult, next in
			if let value = try? Decimal192(next.price) {
				partialResult[next.resourceAddress] = value
			}
		}
	}
}

// MARK: - TokensPriceResponse
struct TokensPriceResponse: Decodable {
	let tokens: [TokenPrice]

	init(tokens: [TokenPrice]) {
		self.tokens = tokens
	}
}

// MARK: TokensPriceResponse.TokenPrice
extension TokensPriceResponse {
	struct TokenPrice: Decodable {
		enum CodingKeys: String, CodingKey {
			case resourceAddress = "resource_address"
			case price = "usd_price"
		}

		let resourceAddress: ResourceAddress
		let price: Double

		init(resourceAddress: ResourceAddress, price: Double) {
			self.resourceAddress = resourceAddress
			self.price = price
		}
	}
}
