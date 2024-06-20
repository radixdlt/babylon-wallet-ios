import CryptoKit
import Foundation
import SargonUniFFI

// MARK: - Mobile2Mobile
public actor Mobile2Mobile {
	private let radixConnectMobile = RadixConnectMobile.live(sessionStorage: SecureSessionStorage())
	private let incomingMessagesSubject: AsyncPassthroughSubject<P2P.RTCIncomingMessage> = .init()

	public func incomingMessages() async -> AnyAsyncSequence<P2P.RTCIncomingMessage> {
		incomingMessagesSubject.share().eraseToAnyAsyncSequence()
	}

	func handleRequest(_ request: URL) async throws {
		let result = try await radixConnectMobile.handleDeepLink(url: request.absoluteString)
		incomingMessagesSubject.send(
			.init(
				result: .success(.request(.dapp(result.interaction))),
				route: .deepLink(result.sessionId),
				requiresOriginVerfication: result.originRequiresValidation
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

// MARK: - SecureSessionStorage
final class SecureSessionStorage: SessionStorage {
	@Dependency(\.secureStorageClient) var secureStorageClient

	func saveSession(sessionId: SessionId, encodedSession: BagOfBytes) async throws {
		try secureStorageClient.saveRadixConnectRelaySession(sessionId, encodedSession)
	}

	func loadSession(sessionId: SessionId) async throws -> BagOfBytes? {
		try secureStorageClient.loadRadixConnectRelaySession(sessionId)
	}
}
