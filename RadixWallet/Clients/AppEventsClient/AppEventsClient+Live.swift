extension AppEventsClient: DependencyKey {
	public static let liveValue: AppEventsClient = {
		@Dependency(\.homeCardsClient) var homeCardsClient

		return .init(
			handleEvent: { event in
				switch event {
				case .appStarted:
					homeCardsClient.walletStarted()
				case .walletCreated:
					homeCardsClient.walletCreated()
				case let .deepLinkReceived(value):
					homeCardsClient.deepLinkReceived(value)
				}
			}
		)
	}()
}
