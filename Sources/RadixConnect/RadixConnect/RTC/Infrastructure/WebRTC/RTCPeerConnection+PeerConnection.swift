import Foundation
import Prelude
import RadixConnectModels
import WebRTC

// MARK: - RTCPeerConnection + PeerConnection
extension RTCPeerConnection: PeerConnection {
	struct FailedToCreateDataChannel: Error {}

	func createDataChannel() throws -> DataChannelClient {
		let config = WebRTCFactory.dataChannelConfig
		guard let dataChannel = dataChannel(forLabel: "\(config.channelId)", configuration: config) else {
			throw FailedToCreateDataChannel()
		}
		let delegate = RTCDataChannelAsyncDelegate()
		dataChannel.delegate = delegate
		return DataChannelClient(dataChannel: dataChannel, delegate: delegate)
	}

	func setLocalDescription(_ description: Either<RTCPrimitive.Offer, RTCPrimitive.Answer>) async throws {
		try await setLocalDescription(.init(from: description))
	}

	func setRemoteDescription(_ description: Either<RTCPrimitive.Offer, RTCPrimitive.Answer>) async throws {
		try await setRemoteDescription(.init(from: description))
	}

	func createLocalOffer() async throws -> RTCPrimitive.Offer {
		.init(from: try await self.offer(for: .negotiationConstraints))
	}

	func createLocalAnswer() async throws -> RTCPrimitive.Answer {
		.init(from: try await self.answer(for: .negotiationConstraints))
	}

	func addRemoteICECandidate(_ candidate: RTCPrimitive.ICECandidate) async throws {
		try await self.add(.init(from: candidate))
	}
}

extension RTCPeerConnection: @unchecked Sendable {}

extension RTCMediaConstraints {
	static var negotiationConstraints: RTCMediaConstraints {
		.init(mandatoryConstraints: [:], optionalConstraints: [:])
	}
}

extension RTCPrimitive.Offer {
	init(from sessionDescription: RTCSessionDescription) {
		self.init(sdp: .init(rawValue: sessionDescription.sdp))
	}
}

extension RTCPrimitive.Answer {
	init(from sessionDescription: RTCSessionDescription) {
		self.init(sdp: .init(rawValue: sessionDescription.sdp))
	}
}

extension RTCSessionDescription {
	convenience init(from sdp: Either<RTCPrimitive.Offer, RTCPrimitive.Answer>) {
		switch sdp {
		case let .left(offer):
			self.init(type: .offer, sdp: offer.sdp.rawValue)
		case let .right(answer):
			self.init(type: .answer, sdp: answer.sdp.rawValue)
		}
	}
}

extension RTCIceCandidate {
	convenience init(from candidate: RTCPrimitive.ICECandidate) {
		self.init(sdp: candidate.sdp.rawValue, sdpMLineIndex: candidate.sdpMLineIndex, sdpMid: candidate.sdpMid)
	}
}
