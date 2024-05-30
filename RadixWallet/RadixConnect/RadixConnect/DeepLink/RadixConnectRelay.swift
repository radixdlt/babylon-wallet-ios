import Foundation

// MARK: - RadixConnectRelay
// A component that interact with the RadixConnectRelay
public struct RadixConnectRelay: DependencyKey {
	public var getRequests: GetRequests
	public var sendResponse: SendResponse
	public var getHandshakeRequest: GetHandshakeRequest
	public var sendHandshakeResponse: SendHandshakeResponse
}

extension RadixConnectRelay {
	public typealias GetRequests = (Session) async throws -> [P2P.RTCMessageFromPeer.Request]
	public typealias SendResponse = (P2P.RTCOutgoingMessage.Response, Session) async throws -> Void
	public typealias GetHandshakeRequest = (Session.ID) async throws -> Session.PeerPublicKey
	public typealias SendHandshakeResponse = (Session.ID, Session.PeerPublicKey) async throws -> Void

	public struct Session: Codable, Sendable {
		public typealias PeerPublicKey = Curve25519.KeyAgreement.PublicKey
		public enum Origin: Codable, Sendable {
			case webDapp(URL)
		}

		public typealias ID = Tagged<Self, String>

		public let id: ID
		public let origin: Origin
		public let encryptionKey: Exactly32Bytes
	}

	public struct HandshakeRequest: Sendable, Decodable {
		let publicKey: Exactly32Bytes
	}

	public struct HandshakeResponse: Sendable, Codable {
		let publicKey: Exactly32Bytes
	}
}

extension RadixConnectRelay {
	public static var liveValue: RadixConnectRelay {
		@Dependency(\.httpClient) var httpClient
		@Dependency(\.secureStorageClient) var secureStorageClient

		let serviceURL = URL(string: "http://radix-connect-relay.radixdlt.com/api/v1")!
		let encryptionScheme = EncryptionScheme.version1

		return .init(
			getRequests: { session in
				let body = Request.getRequests(sessionId: session.id)
				var urlRequest = URLRequest(url: serviceURL)
				urlRequest.httpBody = try JSONEncoder().encode(body)
				urlRequest.httpMethod = "POST"

				let retries = 5
				var attempts = 0

				while attempts < retries {
					do {
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
					} catch {
						print("retrying")
						attempts += 1
						if attempts < retries {
							try await Task.sleep(for: .seconds(1))
						} else {
							throw error // Re-throw the last error after the last attempt
						}
					}
				}
				fatalError("Should not happen")

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
			},
			getHandshakeRequest: { sessionId in
				let body = Request.getHandshakeRequests(sessionId: sessionId)
				var urlRequest = URLRequest(url: serviceURL)
				urlRequest.httpBody = try JSONEncoder().encode(body)
				urlRequest.httpMethod = "POST"

				let retries = 5
				var attempts = 0

				while attempts < retries {
					do {
						loggerGlobal.error("executing get hadnshake request \(urlRequest.debugDescription)")
						let response = try await httpClient.executeRequest(urlRequest)
						let content = try JSONDecoder().decode(HandshakeRequest.self, from: response)

						loggerGlobal.error("response received after \(attempts) retries")

						return try Session.PeerPublicKey(rawRepresentation: content.publicKey.data.data)
					} catch {
						print("retrying")
						attempts += 1
						if attempts < retries {
							try await Task.sleep(for: .seconds(1))
						} else {
							loggerGlobal.error("Bailling out")
							throw error // Re-throw the last error after the last attempt
						}
					}
				}
				fatalError("Should not happen")
			},
			sendHandshakeResponse: { id, key in
				let body = try Request.sendHandshakeResponse(sessionId: id, publicKey: key)
				var urlRequest = URLRequest(url: serviceURL)
				urlRequest.httpBody = try JSONEncoder().encode(body)
				urlRequest.httpMethod = "POST"
				loggerGlobal.error("executing send handhsake response\(urlRequest.debugDescription)")
				_ = try await httpClient.executeRequest(urlRequest)
				loggerGlobal.error("Executed send handshake response")
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
			case sendHandshakeRequest
			case getHandshakeRequest
			case sendHandshakeResponse
			case getHandshakeResponse
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

		static func getHandshakeRequests(sessionId: RadixConnectRelay.Session.ID) -> Self {
			.init(method: .getHandshakeRequest, sessionId: sessionId, data: nil)
		}

		static func sendHandshakeResponse(sessionId: RadixConnectRelay.Session.ID, publicKey: Session.PeerPublicKey) throws -> Self {
			let encoded = try JSONEncoder().encode(HandshakeResponse(publicKey: Exactly32Bytes(hex: publicKey.rawRepresentation.hex)))
			return .init(
				method: .sendHandshakeResponse,
				sessionId: sessionId,
				data: HexCodable(data: encoded)
			)
		}
	}
}

extension DependencyValues {
	public var radixConnectRelay: RadixConnectRelay {
		get { self[RadixConnectRelay.self] }
		set { self[RadixConnectRelay.self] = newValue }
	}
}
