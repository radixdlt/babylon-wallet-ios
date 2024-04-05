import AppsFlyerLib

extension AppsFlyerClient: DependencyKey {
	static var liveValue: AppsFlyerClient {
		@Dependency(\.sensitiveInfoClient) var sensitiveInfoClient

		return .init(
			start: {
				guard
					let devKey = sensitiveInfoClient.read(.appsFlyerDevKey),
					let appId = sensitiveInfoClient.read(.appsFlyerAppId)
				else {
					return
				}
				AppsFlyerLib.shared().appsFlyerDevKey = devKey
				AppsFlyerLib.shared().appleAppID = appId

				#if DEBUG
				AppsFlyerLib.shared().isDebug = true
				#endif

				AppsFlyerLib.shared().start()
			}
		)
	}
}
