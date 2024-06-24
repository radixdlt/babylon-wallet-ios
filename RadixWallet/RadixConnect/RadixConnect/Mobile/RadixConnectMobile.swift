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
