import P2PModels
import WebRTC

// MARK: WebRTCOffer
public extension WebRTCOffer {
	init(rtcSessionDescription: RTCSessionDescription) {
		self.init(sdp: rtcSessionDescription.sdp)
	}

	func rtcSessionDescription() -> RTCSessionDescription {
		.init(type: .offer, sdp: sdp)
	}
}

// MARK: WebRTCAnswer
public extension WebRTCAnswer {
	init(rtcSessionDescription: RTCSessionDescription) {
		self.init(sdp: rtcSessionDescription.sdp)
	}

	func rtcSessionDescription() -> RTCSessionDescription {
		.init(type: .answer, sdp: sdp)
	}
}

// MARK: WebRTCICECandidate
public extension WebRTCICECandidate {
	init(rtcIceCandidate: RTCIceCandidate) {
		self.init(
			sdp: rtcIceCandidate.sdp,
			sdpMid: rtcIceCandidate.sdpMid,
			sdpMLineIndex: Int(rtcIceCandidate.sdpMLineIndex),
			serverUrl: rtcIceCandidate.serverUrl
		)
	}

	func rtc() -> RTCIceCandidate {
		.init(
			sdp: sdp,
			sdpMLineIndex: Int32(sdpMLineIndex),
			sdpMid: sdpMid
		)
	}
}
