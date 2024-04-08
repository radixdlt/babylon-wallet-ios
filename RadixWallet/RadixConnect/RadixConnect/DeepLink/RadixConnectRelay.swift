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

		static func sendRequest(sessionId: SessionId, data: HexCodable) -> Self {
			.init(method: .sendRequest, sessionId: sessionId, data: data)
		}

		static func getRequests(sessionId: String) -> Self {
			.init(method: getRequests, sessionId: sessionId)
		}

		static func sendResponse(sessionId: String, data: String) -> Self {
			.init(method: sendResponse, sessionId: sessionId, data: data)
		}

		static func getResponses(sessionId: String) -> Self {
			.init(method: getRessponses, sessionId: sessionId)
		}
	}
}
