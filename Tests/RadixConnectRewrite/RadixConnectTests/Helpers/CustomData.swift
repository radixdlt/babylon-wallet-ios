import Foundation
@testable import RadixConnect

extension IdentifiedPrimitive {
	static func anyOffer(for id: ClientID) -> IdentifiedPrimitive<RTCPrimitive.Offer> {
		.init(content: RTCPrimitive.Offer(sdp: "Offer SDP \(UUID().uuidString)"), id: id)
	}

	static func anyAnswer(for id: ClientID) -> IdentifiedPrimitive<RTCPrimitive.Answer> {
		.init(content: .any, id: id)
	}

	static func anyICECandidate(for id: ClientID) -> IdentifiedPrimitive<RTCPrimitive.ICECandidate> {
		.init(content: RTCPrimitive.ICECandidate(sdp: "ICECanddiate sdp \(UUID().uuidString)", sdpMLineIndex: 2, sdpMid: "mid"), id: id)
	}
}

extension RTCPrimitive.Answer {
	static var any: Self {
		.init(sdp: "Answer SDP \(UUID().uuidString)")
	}
}

extension ClientID {
	static var any: Self {
		.init(UUID().uuidString)
	}
}

extension RequestID {
	static var any: RequestID {
		.init(rawValue: UUID().uuidString)
	}
}

extension Data {
	static func random(length: Int) throws -> Data {
		Data((0 ..< length).map { _ in UInt8.random(in: UInt8.min ... UInt8.max) })
	}
}
