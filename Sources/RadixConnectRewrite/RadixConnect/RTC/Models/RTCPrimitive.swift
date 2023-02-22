// MARK: - Identified
struct Identified<T, Id> {
	let content: T
	let id: Id
}

// MARK: Equatable
extension Identified: Equatable where T: Equatable, Id: Equatable {}

// MARK: Sendable
extension Identified: Sendable where T: Sendable, Id: Sendable {}

typealias IdentifiedPrimitive<T: Sendable> = Identified<T, ClientID>

// MARK: - RTCPrimitive
enum RTCPrimitive: Equatable, Sendable {
	case offer(RTCPrimitive.Offer)
	case answer(RTCPrimitive.Answer)
	case iceCandidate(RTCPrimitive.ICECandidate)
}

extension RTCPrimitive {
        var offer: Offer? {
                guard case let .offer(offer) = self else {
                        return nil
                }
                return offer
        }

        var answer: Answer? {
                guard case let .answer(answer) = self else {
                        return nil
                }
                return answer
        }

        var iceCandidate: ICECandidate? {
                guard case let .iceCandidate(ice) = self else {
                        return nil
                }
                return ice
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


// MARK: Encodable
extension RTCPrimitive: Encodable {
	func encode(to encoder: Encoder) throws {
		var singleValueContainer = encoder.singleValueContainer()
		switch self {
		case let .offer(value):
			try singleValueContainer.encode(value)
		case let .answer(value):
			try singleValueContainer.encode(value)
		case let .iceCandidate(value):
			try singleValueContainer.encode(value)
		}
	}
}
