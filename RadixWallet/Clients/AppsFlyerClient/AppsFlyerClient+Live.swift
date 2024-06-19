import AppsFlyerLib

// MARK: - AppsFlyerClient + DependencyKey
extension AppsFlyerClient: DependencyKey {
	static var liveValue: AppsFlyerClient {
		@Dependency(\.sensitiveInfoClient) var sensitiveInfoClient
		let state = State()

		actor State {
			let delegate = Delegate()
		}

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

				AppsFlyerLib.shared().deepLinkDelegate = state.delegate

				#if DEBUG
				AppsFlyerLib.shared().isDebug = true
				#endif

				AppsFlyerLib.shared().start()
			},
			continue: { userActivity in
				AppsFlyerLib.shared().continue(userActivity)
			}
		)
	}

	private class Delegate: NSObject, DeepLinkDelegate, @unchecked Sendable {
		func didResolveDeepLink(_ result: DeepLinkResult) {
			if let deepLink = result.deepLink {
				print("M- did resolve deep link. Is deferred: \(deepLink.isDeferred). Click events: \(deepLink.clickEvent)")
			} else if let error = result.error {
				print("M- failed to resolve deep link. Status: \(result.status), Error: \(error)")
			}
		}
	}
}
