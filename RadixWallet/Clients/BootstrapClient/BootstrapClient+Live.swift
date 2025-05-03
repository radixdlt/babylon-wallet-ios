extension BootstrapClient: DependencyKey {
	static var liveValue: BootstrapClient {
		@Dependency(\.appsFlyerClient) var appsFlyerClient
		@Dependency(\.homeCardsClient) var homeCardsClient

		return .init(
			bootstrap: {
				appsFlyerClient.start()
				homeCardsClient.bootstrap()
			}
		)
	}
}
