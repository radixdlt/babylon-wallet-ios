import Foundation

// MARK: - RadixConnectRelay
// A component that interact with the RadixConnectRelay
struct RadixConnectRelay: DependencyKey {
	var getRequests: GetRequests
}

extension RadixConnectRelay {
	typealias SessionId = Tagged<Self, String>
	typealias GetRequests = (SessionId) async throws -> [P2P.RTCMessageFromPeer.Request]
	typealias SendResponse = (P2P.RTCOutgoingMessage.Response, SessionId) async throws -> Void
}

extension RadixConnectRelay {
	static var liveValue: RadixConnectRelay {
		@Dependency(\.httpClient) var httpClient
		@Dependency(\.secureStorageClient) var secureStorageClient

		let serviceURL = URL(string: "https://radix-connect-relay-dev.rdx-works-main.extratools.works/api/v1")!
		let encryptionScheme = EncryptionScheme.version1

		return .init(getRequests: { sessionId in
			let body = Request.getRequests(sessionId: sessionId)
			var urlRequest = URLRequest(url: serviceURL)
			urlRequest.httpBody = try JSONEncoder().encode(body)
			urlRequest.httpMethod = "POST"

			let response = try await httpClient.executeRequest(urlRequest)
			let content = try JSONDecoder().decode([HexCodable].self, from: response)

			let sessionSecrets = try secureStorageClient.loadMobile2MobileSessionSecret(sessionId.rawValue)!
			let walletPrivateKey = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: sessionSecrets.walletPrivateKey.data.data)
			let dAppPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: sessionSecrets.dAppPublicKey.data.data)
			let sharedSecret = try walletPrivateKey.sharedSecretFromKeyAgreement(with: dAppPublicKey)
			return try content.map {
				try encryptionScheme.decrypt(data: $0.data, decryptionKey: .init(data: sharedSecret.data))
			}.map {
				try JSONDecoder().decode(
					P2P.RTCMessageFromPeer.Request.self,
					from: $0
				)
			}
		})
	}
}

// MARK: RadixConnectRelay.Request
extension RadixConnectRelay {
	struct Request: Codable, Sendable {
		enum Method: Codable, Sendable {
			case sendRequest
			case getRequests
			case sendResponse
			case getRessponses
		}

		let method: Method
		let sessionId: RadixConnectRelay.SessionId
		let data: HexCodable?

		static func sendRequest(sessionId: RadixConnectRelay.SessionId, data: HexCodable) -> Self {
			.init(method: .sendRequest, sessionId: sessionId, data: data)
		}

		static func getRequests(sessionId: RadixConnectRelay.SessionId) -> Self {
			.init(method: .getRequests, sessionId: sessionId, data: nil)
		}

		static func sendResponse(sessionId: RadixConnectRelay.SessionId, data: HexCodable) -> Self {
			.init(method: .sendResponse, sessionId: sessionId, data: data)
		}

		static func getResponses(sessionId: RadixConnectRelay.SessionId) -> Self {
			.init(method: .getRessponses, sessionId: sessionId, data: nil)
		}
	}
}
