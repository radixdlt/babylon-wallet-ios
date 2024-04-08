import CryptoKit
import Foundation

// MARK: - Mobile2Mobile
public actor Mobile2Mobile {
	let serviceURL = URL(string: "https://radix-connect-relay-dev.rdx-works-main.extratools.works/api/v1")!
	let encryptionScheme = EncryptionScheme.version1
	@Dependency(\.httpClient) var httpClient
	@Dependency(\.openURL) var openURL
	@Dependency(\.overlayWindowClient) var overlayWindowClient
	@Dependency(\.secureStorageClient) var secureStorageClient
	@Dependency(\.errorQueue) var errorQueue

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
			try await fetchDappRequest(request)
		}
	}
}

extension Mobile2Mobile {
	func getDappReturnURL(_ dAppOrigin: URL) async throws -> URL {
		let wellKnown = try await httpClient.fetchDappWellKnownFile(dAppOrigin)
		guard let returnURL = wellKnown.callbackPath else {
			throw Error.missingDappReturnURL
		}
		return .init(string: dAppOrigin.absoluteString + returnURL)! // dAppOrigin.appending(component: returnURL)
	}

	func linkDapp(_ request: Request.DappLinking) async throws {
		let dappReturnURL = try await getDappReturnURL(request.dAppOrigin)

		loggerGlobal.critical("Creating the Wallet Private/Public key pair")

		let walletPrivateKey = Curve25519.KeyAgreement.PrivateKey()
		let walletPublicKey = walletPrivateKey.publicKey
		let dAppPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: HexCodable32Bytes(hex: request.publicKeyHex).data.data)

		let returnURL = dappReturnURL.appending(queryItems: [
			.init(name: "publicKey", value: walletPublicKey.rawRepresentation.hex),
			.init(name: "sessionId", value: request.sessionId),
		])

		try secureStorageClient.saveMobile2MobileSessionSecret(
			.init(
				sessionId: request.sessionId,
				dAppOrigin: request.dAppOrigin,
				walletPrivateKey: .init(hex: walletPrivateKey.rawRepresentation.hex),
				dAppPublicKey: .init(hex: request.publicKeyHex)
			)
		)

		await openURL(returnURL)
	}

	func sendResponse(_ response: P2P.RTCOutgoingMessage.Response, sessionId: String) async throws {
		//        let body = GetRequests(sessionId: request.sessionId)
		//        var urlRequest = URLRequest(url: serviceURL)
		//        urlRequest.httpBody = try JSONEncoder().encode(body)
		//        urlRequest.httpMethod = "POST"
		do {
			let sessionSecrets = try secureStorageClient.loadMobile2MobileSessionSecret(sessionId)
			guard let sessionSecrets else {
				return
			}
			let walletPrivateKey = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: sessionSecrets.walletPrivateKey.data.data)
			let dAppPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: sessionSecrets.dAppPublicKey.data.data)
			let sharedSecret = try walletPrivateKey.sharedSecretFromKeyAgreement(with: dAppPublicKey)

			var urlRequest = URLRequest(url: serviceURL)
			urlRequest.httpMethod = "POST"
			urlRequest.allHTTPHeaderFields = [
				"accept": "application/json",
				"Content-Type": "application/json",
			]

			let encodedResponse = try JSONEncoder().encode(response)

			let encryptedResponse = try encryptionScheme.encrypt(
				data: encodedResponse,
				encryptionKey: .init(data: sharedSecret.data)
			)

			let payload = HexCodable(data: encryptedResponse)
			let sendResponse = SendResponse(sessionId: sessionId, data: payload.hex())

			urlRequest.httpBody = try JSONEncoder().encode(sendResponse)

			try await httpClient.executeRequest(urlRequest)

			let intId = switch response {
			case let .dapp(response):
				response.id.rawValue
			}

			let returnURL = URL(string: sessionSecrets.dAppOrigin.absoluteString + "#connect")?.appending(queryItems: [
				.init(name: "sessionId", value: sessionId),
				.init(name: "interactionId", value: intId),
			])
			await openURL(returnURL!)
		} catch {
			errorQueue.schedule(error)
		}
	}

	func fetchDappRequest(_ request: Request.DappRequest) async throws {
		let body = GetRequests(sessionId: request.sessionId)
		var urlRequest = URLRequest(url: serviceURL)
		urlRequest.httpBody = try JSONEncoder().encode(body)
		urlRequest.httpMethod = "POST"
		do {
			let response = try await httpClient.executeRequest(urlRequest)
			let content = try JSONDecoder().decode([HexCodable].self, from: response)
			let sessionSecrets = try secureStorageClient.loadMobile2MobileSessionSecret(request.sessionId)
			guard let sessionSecrets else {
				return
			}
			let walletPrivateKey = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: sessionSecrets.walletPrivateKey.data.data)
			let dAppPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: sessionSecrets.dAppPublicKey.data.data)
			let sharedSecret = try walletPrivateKey.sharedSecretFromKeyAgreement(with: dAppPublicKey)
			let receivedRequest = try content.map {
				try encryptionScheme.decrypt(data: $0.data, decryptionKey: .init(data: sharedSecret.data))
			}.map {
				try JSONDecoder().decode(
					P2P.RTCMessageFromPeer.Request.self,
					from: $0
				)
			}.first {
				switch $0 {
				case let .dapp(dApp):
					dApp.id == .init(rawValue: request.interactionId)
				}
			}

			guard let receivedRequest else {
				return
			}

			incomingMessagesSubject.send(.init(result: .success(.request(receivedRequest)), route: .deepLink(request.sessionId)))
			print(request)
		} catch {
			errorQueue.schedule(error)
		}
	}
}

extension Mobile2Mobile {
	public enum Request: Sendable {
		case linking(DappLinking)
		case request(DappRequest)

		public struct DappLinking: Sendable {
			public let dAppOrigin: URL
			public let publicKeyHex: String
			public let sessionId: String
		}

		public struct DappRequest: Sendable {
			public let sessionId: String
			public let interactionId: String
		}
	}

	public typealias HandleRequest = (Request) async throws -> Void
}

extension Mobile2Mobile {
	public struct SessionConnection: Codable, Sendable {
		public typealias ID = String
		public var id: ID {
			sessionId
		}

		public let sessionId: String
		public let dAppOrigin: URL
		public let walletPrivateKey: HexCodable32Bytes
		public let dAppPublicKey: HexCodable32Bytes
	}

	public enum Error: Swift.Error {
		case missingDappReturnURL
	}

	struct GetRequests: Codable {
		let method: String = "getRequests"
		let sessionId: String
	}

	struct SendResponse: Codable {
		let method: String = "sendResponse"
		let sessionId: String
		let data: String
	}
}
