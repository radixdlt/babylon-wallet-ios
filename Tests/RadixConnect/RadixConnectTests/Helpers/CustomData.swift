import Foundation
@testable import RadixConnect
import RadixConnectModels

extension IdentifiedPrimitive {
	static func anyOffer(for id: RemoteClientID) -> IdentifiedPrimitive<RTCPrimitive> {
		.init(content: .offer(.any), id: id)
	}

	static func anyAnswer(for id: RemoteClientID) -> IdentifiedPrimitive<RTCPrimitive> {
		.init(content: .answer(.any), id: id)
	}

	static func anyICECandidate(for id: RemoteClientID) -> IdentifiedPrimitive<RTCPrimitive> {
		.init(content: .iceCandidate(.any), id: id)
	}
}

extension RTCPrimitive.Answer {
	static var any: Self {
		.init(sdp: "Answer SDP \(UUID().uuidString)")
	}
}

extension RTCPrimitive.Offer {
	static var any: Self {
		.init(sdp: "Offer SDP \(UUID().uuidString)")
	}
}

extension RTCPrimitive.ICECandidate {
	static var any: Self {
		.init(sdp: "ICECanddiate sdp \(UUID().uuidString)", sdpMLineIndex: 2, sdpMid: "mid")
	}
}

extension RemoteClientID {
	static var any: Self {
		.init(UUID().uuidString)
	}
}

extension SignalingClient.ClientMessage.RequestID {
	static var any: Self {
		.init(rawValue: UUID().uuidString)
	}
}

extension Data {
	static func random(length: Int) throws -> Data {
		Data((0 ..< length).map { _ in UInt8.random(in: UInt8.min ... UInt8.max) })
	}
}
