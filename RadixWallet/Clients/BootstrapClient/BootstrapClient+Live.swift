import Nuke

extension BootstrapClient: DependencyKey {
	static var liveValue: BootstrapClient {
		@Dependency(\.appsFlyerClient) var appsFlyerClient
		@Dependency(\.homeCardsClient) var homeCardsClient

		return .init(
			bootstrap: {
				appsFlyerClient.start()
				homeCardsClient.bootstrap()

				ImageDecoderRegistry.shared.register { context in
					let isSVG = context.urlResponse?.url?.isSVG ?? false
					return isSVG ? ImageDecoders.Empty() : nil
				}
			}
		)
	}
}
