extension DeepLinkHandlerClient {
	static let liveValue: DeepLinkHandlerClient = {
		@Dependency(\.radixConnectClient) var radixConnectClient
		@Dependency(\.errorQueue) var errorQueue

		struct State {
			/// The deepLink is buffered so it can be handled at the appropriate time based on the app state.
			/// For example, if the deepLink is received while user is in onboarding flow,
			/// we would want to handle it only when user did land on home screen.
			var bufferedDeepLink: URL?
		}

		var state = State()

		return DeepLinkHandlerClient(
			handleDeepLink: {
				guard let url = state.bufferedDeepLink else {
					return
				}
				loggerGlobal.debug("Handling deepLink url \(url.absoluteString)")
				state.bufferedDeepLink = nil
				Task {
					do {
						try await radixConnectClient.handleDappDeepLink(url)
					} catch {
						errorQueue.schedule(error)
					}
				}
			},
			setDeepLink: {
				loggerGlobal.debug("Received deepLink url \($0.absoluteString)")
				state.bufferedDeepLink = $0
			},
			hasDeepLink: {
				state.bufferedDeepLink != nil
			}
		)
	}()
}
