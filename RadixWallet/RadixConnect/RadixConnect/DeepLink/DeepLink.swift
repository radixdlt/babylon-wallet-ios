import CryptoKit
import Foundation

// MARK: - Mobile2Mobile
public actor Mobile2Mobile {
	let serviceURL = URL(string: "https://radix-connect-relay-dev.rdx-works-main.extratools.works/api/v1")!
	let encryptionScheme = EncryptionScheme.version1
	@Dependency(\.overlayWindowClient) var overlayWindowClient
	@Dependency(\.radixConnectRelay) var radixConnectRelay
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.secureStorageClient) var secureStorageClient
	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.cacheClient) var cacheClient
	@Dependency(\.gatewayAPIClient) var gatewayAPIClient
	@Dependency(\.dappInteractionClient) var dappInteractionClient

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
	func linkDapp(_ request: Request.DappLinking) async throws {
		switch request.origin {
		case let .webDapp(dAppOrigin):
			loggerGlobal.critical("Creating the Wallet Private/Public key pair")

			let walletPrivateKey = Curve25519.KeyAgreement.PrivateKey()
			let walletPublicKeyHex = walletPrivateKey.publicKey.rawRepresentation.hex()

			let sharedSecret = try walletPrivateKey.sharedSecretFromKeyAgreement(with: request.publicKey)
			let encryptionKey = SymmetricKey(data: sharedSecret.data)

			try secureStorageClient.saveRadixConnectRelaySession(
				.init(
					id: request.sessionId,
					origin: request.origin,
					encryptionKey: .init(hex: encryptionKey.hex)
				)
			)

			_ = await dappInteractionClient.addWalletInteraction(
				.verify(.init(
					dappOrigin: dAppOrigin,
					publicKeyHex: walletPublicKeyHex,
					sessionId: request.sessionId.rawValue,
					browser: request.browser
				)),
				.dappVerification
			)
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
			public let publicKey: Curve25519.KeyAgreement.PublicKey
			public let browser: String
		}

		public struct DappRequest: Sendable {
			public let sessionId: RadixConnectRelay.Session.ID
			public let interactionId: String
		}
	}

	public typealias HandleRequest = (Request) async throws -> Void
}
