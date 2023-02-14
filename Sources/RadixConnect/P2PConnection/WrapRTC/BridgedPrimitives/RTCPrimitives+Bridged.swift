import P2PModels
import WebRTC

// MARK: WebRTCOffer
extension WebRTCOffer {
	public init(rtcSessionDescription: RTCSessionDescription) {
		self.init(sdp: rtcSessionDescription.sdp)
	}

	public func rtcSessionDescription() -> RTCSessionDescription {
		.init(type: .offer, sdp: sdp)
	}
}

// MARK: WebRTCAnswer
extension WebRTCAnswer {
	public init(rtcSessionDescription: RTCSessionDescription) {
		self.init(sdp: rtcSessionDescription.sdp)
	}

	public func rtcSessionDescription() -> RTCSessionDescription {
		.init(type: .answer, sdp: sdp)
	}
}

// MARK: WebRTCICECandidate
extension WebRTCICECandidate {
	public init(rtcIceCandidate: RTCIceCandidate) {
		self.init(
			sdp: rtcIceCandidate.sdp,
			sdpMid: rtcIceCandidate.sdpMid,
			sdpMLineIndex: Int(rtcIceCandidate.sdpMLineIndex),
			serverUrl: rtcIceCandidate.serverUrl
		)
	}

	public func rtc() -> RTCIceCandidate {
		.init(
			sdp: sdp,
			sdpMLineIndex: Int32(sdpMLineIndex),
			sdpMid: sdpMid
		)
	}
}
