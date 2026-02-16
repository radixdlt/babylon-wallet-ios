extension BootstrapClient: DependencyKey {
	static var liveValue: BootstrapClient {
		@Dependency(\.homeCardsClient) var homeCardsClient

		return .init(
			bootstrap: {
				homeCardsClient.bootstrap()
			}
		)
	}
}
