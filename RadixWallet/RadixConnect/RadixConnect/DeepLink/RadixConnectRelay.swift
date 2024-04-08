import Foundation

// MARK: - RadixConnectRelay
// A component that interact with the RadixConnectRelay
enum RadixConnectRelay {
	typealias SessionId = Tagged<Self, String>
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
