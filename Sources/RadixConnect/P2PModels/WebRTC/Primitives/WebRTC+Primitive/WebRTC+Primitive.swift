import Foundation

// MARK: - WebRTCPrimitiveProtocol
public protocol WebRTCPrimitiveProtocol: Sendable, Hashable, Codable, CustomStringConvertible {
	var sdp: String { get }
}

// MARK: - WebRTCPrimitive
public enum WebRTCPrimitive: Sendable, Hashable, Encodable, CustomStringConvertible {
	case offer(WebRTCOffer)
	case answer(WebRTCAnswer)
	case iceCandidate(WebRTCICECandidate)
}

public extension WebRTCPrimitive {
	var offer: WebRTCOffer? {
		guard case let .offer(offer) = self else {
			return nil
		}
		return offer
	}

	var answer: WebRTCAnswer? {
		guard case let .answer(answer) = self else {
			return nil
		}
		return answer
	}

	var iceCandidate: WebRTCICECandidate? {
		guard case let .iceCandidate(iceCandidate) = self else {
			return nil
		}
		return iceCandidate
	}
}

public extension WebRTCPrimitive {
	var description: String {
		switch self {
		case let .offer(offer):
			return "offer(\(offer.description(includeTypeName: false))"
		case let .answer(answer):
			return "answer(\(answer.description(includeTypeName: false)))"
		case let .iceCandidate(iceCandidate):
			return "iceCandidate(\(iceCandidate.description(includeTypeName: false)))"
		}
	}
}

#if DEBUG
public extension WebRTCPrimitive {
	static let placeholder = Self.offer(.placeholder)
}
#endif // DEBUG
