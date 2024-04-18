import CryptoKit
import Foundation

// MARK: - Mobile2Mobile
public actor Mobile2Mobile {
	let serviceURL = URL(string: "https://radix-connect-relay-dev.rdx-works-main.extratools.works/api/v1")!
	let encryptionScheme = EncryptionScheme.version1
	@Dependency(\.httpClient) var httpClient
	@Dependency(\.openURL) var openURL
	@Dependency(\.overlayWindowClient) var overlayWindowClient
	@Dependency(\.radixConnectRelay) var radixConnectRelay
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.secureStorageClient) var secureStorageClient

	private let incomingMessagesSubject: AsyncPassthroughSubject<P2P.RTCIncomingMessage> = .init()

	/// A **multicasted** async sequence for received message from ALL RTCClients.
	public func incomingMessages() async -> AnyAsyncSequence<P2P.RTCIncomingMessage> {
		incomingMessagesSubject.share().eraseToAnyAsyncSequence()
	}

	func handleRequest(_ request: Request) async throws {
		switch request {
		case let .linking(linkingRequest):
			try await linkDapp(linkingRequest)
		case let .request(request):
			try await handleDeepLinkRequest(request)
		}
	}
}

extension Mobile2Mobile {
	func getDappReturnURL(_ dAppOrigin: URL) async throws -> URL {
		let wellKnown = try await httpClient.fetchDappWellKnownFile(dAppOrigin)
		guard let returnURL = wellKnown.callbackPath else {
			fatalError()
			// throw Error.missingDappReturnURL
		}
		return .init(string: dAppOrigin.absoluteString + returnURL)! // dAppOrigin.appending(component: returnURL)
	}

	func linkDapp(_ request: Request.DappLinking) async throws {
		switch request.origin {
		case let .webDapp(dAppOrigin):
			let dAppPublicKey = try await radixConnectRelay.getHandshakeRequest(request.sessionId)
			let dappReturnURL = try await getDappReturnURL(dAppOrigin)

			loggerGlobal.critical("Creating the Wallet Private/Public key pair")

			let walletPrivateKey = Curve25519.KeyAgreement.PrivateKey()
			let walletPublicKey = walletPrivateKey.publicKey

			let sharedSecret = try walletPrivateKey.sharedSecretFromKeyAgreement(with: dAppPublicKey)
			let encryptionKey = SymmetricKey(data: sharedSecret.data)

			try secureStorageClient.saveRadixConnectRelaySession(
				.init(
					id: request.sessionId,
					origin: request.origin,
					encryptionKey: .init(hex: encryptionKey.hex)
				)
			)

			try await radixConnectRelay.sendHandshakeResponse(request.sessionId, walletPublicKey)

			let returnURL = dappReturnURL.appending(queryItems: [
				.init(name: "sessionId", value: request.sessionId.rawValue),
			])

			await overlayWindowClient.scheduleAlertAutoDimiss(.init(title: {
				.init("Verifying dApp link")
			}))

			await openURL(returnURL)
		}
	}

	func sendResponse(
		_ response: P2P.RTCOutgoingMessage.Response,
		sessionId: RadixConnectRelay.Session.ID
	) async throws {
		guard let session = try secureStorageClient.loadRadixConnectRelaySession(sessionId) else {
			return
		}

		try await radixConnectRelay.sendResponse(response, session)
		let intId = switch response {
		case let .dapp(response):
			response.id.rawValue
		}

		switch session.origin {
		case let .webDapp(dAppOrigin):
			let returnURL = URL(string: dAppOrigin.absoluteString + "#connect")?.appending(queryItems: [
				.init(name: "sessionId", value: sessionId.rawValue),
				.init(name: "interactionId", value: intId),
			])
			await openURL(returnURL!)
		}
	}

	func handleDeepLinkRequest(_ request: Request.DappRequest) async throws {
		guard let session = try secureStorageClient.loadRadixConnectRelaySession(request.sessionId) else {
			return
		}

		let receivedRequest = try await radixConnectRelay
			.getRequests(session)
			.first {
				switch $0 {
				case let .dapp(dApp):
					dApp.id == .init(rawValue: request.interactionId)
				}
			}

		guard let receivedRequest else {
			return
		}

		incomingMessagesSubject.send(.init(result: .success(.request(receivedRequest)), route: .deepLink(request.sessionId)))
	}
}

extension Mobile2Mobile {
	public enum Request: Sendable {
		case linking(DappLinking)
		case request(DappRequest)

		public struct DappLinking: Sendable {
			public let origin: RadixConnectRelay.Session.Origin
			public let sessionId: RadixConnectRelay.Session.ID
		}

		public struct DappRequest: Sendable {
			public let sessionId: RadixConnectRelay.Session.ID
			public let interactionId: String
		}
	}

	public typealias HandleRequest = (Request) async throws -> Void
}
