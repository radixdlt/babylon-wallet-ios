import AppsFlyerLib

extension AppsFlyerClient: DependencyKey {
	static var liveValue: AppsFlyerClient {
		@Dependency(\.sensitiveInfoClient) var sensitiveInfoClient

		return .init(
			start: {
				AppsFlyerLib.shared().appsFlyerDevKey = sensitiveInfoClient.read(.appsFlyerDevKey)
				AppsFlyerLib.shared().appleAppID = sensitiveInfoClient.read(.appsFlyerAppId)

				#if DEBUG
				AppsFlyerLib.shared().isDebug = true
				#endif

				AppsFlyerLib.shared().start()
			}
		)
	}
}
