import SargonUniFFI

// MARK: - RadixConnectMobile
/// A very thin wrapper around Sargon.RadixConnectMobile.
/// It mainly initializes the `live` version Sargon.RadixConnectMobile and
/// exposes the incomming messages stream.
struct RadixConnectMobile {
	private let radixConnectMobile = Sargon.RadixConnectMobile.live(sessionStorage: SecureSessionStorage())
	private let incomingMessagesSubject: AsyncReplaySubject<P2P.RTCIncomingMessage> = .init(bufferSize: 1)
}

extension RadixConnectMobile {
	func incomingMessages() async -> AnyAsyncSequence<P2P.RTCIncomingMessage> {
		incomingMessagesSubject.share().eraseToAnyAsyncSequence()
	}

	func handleRequest(_ request: URL) async throws {
		@Dependency(\.continuousClock) var clock
		// A slight delay before handling the request.
		//
		// This is mainly added to fix the following issue:
		// In some cases the Wallet will show the "Failed to validate dApp" alert.
		//
		// The cause for this issue is that during dApp validation, when Dev mode is not enabled,
		// network requests are being made, and seldomly, but quite consistent, the OS will terminate
		// the request with the quite obscure message - "Network connection lost".
		// Likely that this is because the app is not fully in foreground at the moment the request is being made.
		// So adding a small delay allows the OS to be ready to handle the request. Still, this assumption is based
		// purely on expirementation, and there might be some other more robust fix.
		try? await clock.sleep(for: .milliseconds(100))

		let result = try await radixConnectMobile.handleDeepLink(url: request.absoluteString)
		incomingMessagesSubject.send(
			.init(
				result: .success(.request(.dapp(result.interaction))),
				route: .deepLink(result.sessionId),
				originRequiresValidation: result.originRequiresValidation
			)
		)
	}

	func sendResponse(
		_ response: P2P.RTCOutgoingMessage.Response,
		sessionId: SessionId
	) async throws {
		switch response {
		case let .dapp(walletToDappInteractionResponse):
			try await radixConnectMobile.sendDappInteractionResponse(
				walletResponse: .init(
					sessionId: sessionId,
					response: walletToDappInteractionResponse
				)
			)
		}
	}
}
