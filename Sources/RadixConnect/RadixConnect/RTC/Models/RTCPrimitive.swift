import RadixConnectModels
import Tagged

/// The RTCPrimitive with its respective remote client ID.
/// The is `T` to allow to either embed the full RTCPrimitive type or a specifc primitive - Offer, Answer, ICECanidate.
typealias IdentifiedPrimitive<T: Sendable> = Identified<T, RemoteClientID>

// MARK: - RTCPrimitive
/// Describes the possible RTC primitive exchanged during the WebRTC negotiation
enum RTCPrimitive: Equatable, Sendable {
	case offer(RTCPrimitive.Offer)
	case answer(RTCPrimitive.Answer)
	case iceCandidate(RTCPrimitive.ICECandidate)
}

extension RTCPrimitive {
	enum SDPTag {}
	typealias SDP = Tagged<SDPTag, String>

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

	struct ICECandidate: Sendable, Codable, Equatable {
		let candidate: SDP
		var sdp: SDP { candidate }
		let sdpMLineIndex: Int32
		let sdpMid: String?

		init(sdp: SDP, sdpMLineIndex: Int32, sdpMid: String?) {
			self.candidate = sdp
			self.sdpMLineIndex = sdpMLineIndex
			self.sdpMid = sdpMid
		}
	}
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
