import Foundation

// MARK: - RadixConnectRelay
// A component that interact with the RadixConnectRelay
public struct RadixConnectRelay: DependencyKey {
	public var getRequests: GetRequests
	public var sendResponse: SendResponse
}

extension RadixConnectRelay {
	public typealias GetRequests = (Session) async throws -> [P2P.RTCMessageFromPeer.Request]
	public typealias SendResponse = (P2P.RTCOutgoingMessage.Response, Session) async throws -> Void

	public struct Session: Codable, Sendable {
		public enum Origin: Codable, Sendable {
			case webDapp(URL)
		}

		public typealias ID = Tagged<Self, String>

		public let id: ID
		public let origin: Origin
		public let encryptionKey: HexCodable32Bytes
	}
}

extension RadixConnectRelay {
	public static var liveValue: RadixConnectRelay {
		@Dependency(\.httpClient) var httpClient
		@Dependency(\.secureStorageClient) var secureStorageClient

		let serviceURL = URL(string: "https://radix-connect-relay-dev.rdx-works-main.extratools.works/api/v1")!
		let encryptionScheme = EncryptionScheme.version1

		return .init(
			getRequests: { session in
				let body = Request.getRequests(sessionId: session.id)
				var urlRequest = URLRequest(url: serviceURL)
				urlRequest.httpBody = try JSONEncoder().encode(body)
				urlRequest.httpMethod = "POST"

				let response = try await httpClient.executeRequest(urlRequest)
				let content = try JSONDecoder().decode([HexCodable].self, from: response)

				return try content.map {
					try encryptionScheme.decrypt(data: $0.data, decryptionKey: .init(data: session.encryptionKey.data.data))
				}.map {
					try JSONDecoder().decode(
						P2P.RTCMessageFromPeer.Request.self,
						from: $0
					)
				}
			},
			sendResponse: { response, session in
				let encodedResponse = try JSONEncoder().encode(response)
				let encryptedResponse = try encryptionScheme.encrypt(
					data: encodedResponse,
					encryptionKey: .init(data: session.encryptionKey.data.data)
				)

				let payload = HexCodable(data: encryptedResponse)
				let sendResponse = Request.sendResponse(sessionId: session.id, data: payload)

				var urlRequest = URLRequest(url: serviceURL)
				urlRequest.httpMethod = "POST"
				urlRequest.allHTTPHeaderFields = [
					"accept": "application/json",
					"Content-Type": "application/json",
				]

				urlRequest.httpBody = try JSONEncoder().encode(sendResponse)

				_ = try await httpClient.executeRequest(urlRequest)
			}
		)
	}
}

// MARK: RadixConnectRelay.Request
extension RadixConnectRelay {
	struct Request: Codable, Sendable {
		enum Method: String, Codable, Sendable {
			case sendRequest
			case getRequests
			case sendResponse
			case getRessponses
		}

		let method: Method
		let sessionId: RadixConnectRelay.Session.ID
		let data: HexCodable?

		static func sendRequest(sessionId: RadixConnectRelay.Session.ID, data: HexCodable) -> Self {
			.init(method: .sendRequest, sessionId: sessionId, data: data)
		}

		static func getRequests(sessionId: RadixConnectRelay.Session.ID) -> Self {
			.init(method: .getRequests, sessionId: sessionId, data: nil)
		}

		static func sendResponse(sessionId: RadixConnectRelay.Session.ID, data: HexCodable) -> Self {
			.init(method: .sendResponse, sessionId: sessionId, data: data)
		}

		static func getResponses(sessionId: RadixConnectRelay.Session.ID) -> Self {
			.init(method: .getRessponses, sessionId: sessionId, data: nil)
		}
	}
}

extension DependencyValues {
	public var radixConnectRelay: RadixConnectRelay {
		get { self[RadixConnectRelay.self] }
		set { self[RadixConnectRelay.self] = newValue }
	}
}
