import AppsFlyerLib

// MARK: - AppsFlyerClient + DependencyKey
extension AppsFlyerClient: DependencyKey {
	static var liveValue: AppsFlyerClient {
		@Dependency(\.sensitiveInfoClient) var sensitiveInfoClient

		return .init(
			start: {
				guard
					let devKey = sensitiveInfoClient.read(.appsFlyerDevKey),
					let appId = sensitiveInfoClient.read(.appsFlyerAppId)
				else {
					loggerGlobal.info("Skipping AppsFlyer start as keys are missing")
					return
				}
				AppsFlyerLib.shared().appsFlyerDevKey = devKey
				AppsFlyerLib.shared().appleAppID = appId

//				#if DEBUG
				AppsFlyerLib.shared().isDebug = true
//				#endif

				DebugInfo.shared.add("AppsFlyerLib started")
				AppsFlyerLib.shared().start()
			}
		)
	}
}
