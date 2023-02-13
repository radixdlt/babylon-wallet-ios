// MARK: - RTCPrimitive

struct Identified<T, Id> {
        let content: T
        let id: Id
}

extension Identified: Equatable where T: Equatable, Id: Equatable {}
extension Identified: Sendable where T: Sendable, Id: Sendable {}

typealias IdentifiedPrimitive<T: Sendable> = Identified<T, ClientID>

enum RTCPrimitive: Equatable, Sendable {
        case offer(IdentifiedPrimitive<RTCPrimitive.Offer>)
        case answer(IdentifiedPrimitive<RTCPrimitive.Answer>)
        case iceCandidate(IdentifiedPrimitive<RTCPrimitive.ICECandidate>)
}

extension RTCPrimitive {
        var clientId: ClientID {
                switch self {
                case let .offer(offer):
                        return offer.id
                case let .answer(answer):
                        return answer.id
                case let .iceCandidate(iceCandidate):
                        return iceCandidate.id
                }
        }
}

extension RTCPrimitive {
	struct Offer: Sendable, Codable, Equatable {
		let sdp: SDP
		init(sdp: SDP) {
			self.sdp = sdp
		}
	}

	struct Answer: Sendable, Codable, Equatable {
		let sdp: SDP
		init(sdp: SDP) {
			self.sdp = sdp
		}
	}

	public struct ICECandidate: Sendable, Codable, Equatable {
		public let candidate: SDP
		public var sdp: SDP { candidate }
		public let sdpMLineIndex: Int32
		public let sdpMid: String?

		public init(sdp: SDP, sdpMLineIndex: Int32, sdpMid: String?) {
			self.candidate = sdp
			self.sdpMLineIndex = sdpMLineIndex
			self.sdpMid = sdpMid
		}
	}
}

extension RTCPrimitive {
	var offer: IdentifiedPrimitive<Offer>? {
		guard case let .offer(offer) = self else {
			return nil
		}
		return offer
	}

	var answer: IdentifiedPrimitive<Answer>? {
		guard case let .answer(answer) = self else {
			return nil
		}
		return answer
	}

	var addICE: IdentifiedPrimitive<ICECandidate>? {
		guard case let .iceCandidate(ice) = self else {
			return nil
		}
		return ice
	}
}

// MARK: Encodable
extension RTCPrimitive: Encodable {
	func encode(to encoder: Encoder) throws {
		var singleValueContainer = encoder.singleValueContainer()
		switch self {
		case let .offer(value):
                        try singleValueContainer.encode(value.content)
		case let .answer(value):
                        try singleValueContainer.encode(value.content)
		case let .iceCandidate(value):
                        try singleValueContainer.encode(value.content)
		}
	}
}
