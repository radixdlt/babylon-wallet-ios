extension TokenPricesClient {
	public static let liveValue: TokenPricesClient = {
		@Dependency(\.httpClient) var httpClient
		@Dependency(\.jsonDecoder) var jsonDecoder
		@Dependency(\.jsonEncoder) var jsonEncoder
		@Dependency(\.cacheClient) var cacheClient
		#if DEBUG
		let rootURL = URL(string: "https://dev-token-price.extratools.works")!
		#else
		let rootURL = URL(string: "https://token-price-service.radixdlt.com")!
		#endif

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
	fileprivate init(_ tokenPricesResponse: TokensPriceResponse) {
		let formatter = NumberFormatter()
		formatter.numberStyle = .decimal
		formatter.maximumFractionDigits = Int(RETDecimal.maxDivisibility)
		formatter.roundingMode = .down

		self = tokenPricesResponse.tokens.reduce(into: [:]) { partialResult, next in
			let trimmed = formatter.string(for: next.price) ?? ""
			if let value = try? RETDecimal(value: trimmed) {
				partialResult[next.resourceAddress] = value
			}
		}
	}
}

// MARK: - TokensPriceResponse
private struct TokensPriceResponse: Decodable {
	public let tokens: [TokenPrice]
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
	}
}
