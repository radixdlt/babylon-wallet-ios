extension DeepLinkHandlerClient {
	public static var liveValue: DeepLinkHandlerClient {
		@Dependency(\.radixConnectClient) var radixConnectClient
		@Dependency(\.errorQueue) var errorQueue

		struct State {
			var bufferedDeepLink: URL?
		}

		var state = State()

		return DeepLinkHandlerClient(
			handleDeepLink: {
				if let url = state.bufferedDeepLink {
					loggerGlobal.debug("Handling deepLink url \(url.absoluteString)")
					state.bufferedDeepLink = nil
					Task {
						do {
							try await radixConnectClient.handleDappDeepLink(url)
						} catch {
							errorQueue.schedule(error)
						}
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
	}
}
