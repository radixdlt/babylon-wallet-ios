extension BootstrapClient: DependencyKey {
	static var liveValue: BootstrapClient {
		@Dependency(\.appsFlyerClient) var appsFlyerClient
		@Dependency(\.homeCardsClient) var homeCardsClient
		@Dependency(\.dappInteractionClient) var dappInteractionClient
		@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient

		return .init(
			bootstrap: {
				ProfileStore.shared.bootstrap()
				// appsFlyerClient.start()
				homeCardsClient.bootstrap()
				dappInteractionClient.bootstrap()
				accountPortfoliosClient.bootstrap()
			}
		)
	}
}
