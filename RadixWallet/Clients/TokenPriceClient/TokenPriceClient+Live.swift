import Sargon

extension TokenPricesClient {
	static let liveValue: TokenPricesClient = .init(
		getTokenPrices: { request, refresh in
			try await SargonOS.shared.fetchFungibleFiatValues(
				tokens: request.tokens,
				lsus: [],
				currency: request.currency,
				forceFetch: refresh
			)
		},
		getTokenPriceServices: {
			try SargonOs.shared.tokenPriceServicesOnCurrentNetwork()
		},
		addTokenPriceService: { baseURL in
			try await SargonOs.shared.addTokenPriceServiceOnCurrentNetwork(baseUrl: baseURL)
		},
		deleteTokenPriceService: { baseURL in
			try await SargonOs.shared.deleteTokenPriceServiceOnCurrentNetwork(baseUrl: baseURL)
		}
	)
}
