// MARK: - ClientMessage
struct ClientMessage: Sendable, Codable, Equatable {
	enum Method: String, Sendable, Codable, Equatable {
		case offer
		case answer
		case iceCandidate
		case iceCandidates
	}

	enum Source: String, Sendable, Codable, Equatable {
		case wallet
		case `extension`
	}

	let requestId: RequestID
	let method: Method
	let source: Source
	let connectionId: SignalingServerConnectionID
	let encryptedPayload: EncryptedPayload
}

extension ClientMessage.Method {
	init(from primitive: RTCPrimitive) {
		switch primitive {
		case .offer:
			self = .offer
		case .answer:
			self = .answer
		case .addICE:
			self = .iceCandidate
		}
	}
}
