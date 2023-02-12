import P2PModels
import Prelude

// MARK: - WebRTCPeerConnectionDelegate
public protocol WebRTCPeerConnectionDelegate: AnyObject {
	func peerConnection(id: P2PConnectionID, didChangePeerConnectionState peerConnectionState: PeerConnectionState)
	func peerConnection(id: P2PConnectionID, didChangeSignalingState signalingState: SignalingState)

	/// This should maybe act as the canonical indication of our connection state, since it is what is used in Googles example app and driving the UI: https://chromium.googlesource.com/external/webrtc/+/refs/heads/main/examples/objc/AppRTCMobile/ARDAppClient.m#405
	func peerConnection(id: P2PConnectionID, didChangeICEConnectionState iceConnectionState: ICEConnectionState)

	func peerConnection(id: P2PConnectionID, didChangeICEGatheringState iceGatheringState: ICEGatheringState)
	func peerConnection(id: P2PConnectionID, didGenerateICECandidate iceCandidate: WebRTCICECandidate)
	func peerConnection(id: P2PConnectionID, didRemoveICECandidates iceCandidates: [WebRTCICECandidate])
	func peerConnection(id: P2PConnectionID, didAddStreamWithID streamID: String)
	func peerConnection(id: P2PConnectionID, didRemoveStreamWithID streamID: String)
	func peerConnection(id: P2PConnectionID, didOpenDataChannel labelledID: DataChannelLabelledID)
	func peerConnectionShouldNegotiate(id: P2PConnectionID)
}

extension WebRTCPeerConnectionDelegate {
	public func peerConnection(id: P2PConnectionID, didChangePeerConnectionState peerConnectionState: PeerConnectionState) {
		loggerGlobal.warning("NOT IMPLEMENTED: \(#function), IGNORED \(String(describing: peerConnectionState))")
	}

	public func peerConnection(id: P2PConnectionID, didChangeSignalingState signalingState: SignalingState) {
		loggerGlobal.warning("NOT IMPLEMENTED: \(#function), IGNORED \(String(describing: signalingState))")
	}

	public func peerConnection(id: P2PConnectionID, didChangeICEConnectionState iceConnectionState: ICEConnectionState) {
		loggerGlobal.warning("NOT IMPLEMENTED: \(#function), IGNORED \(String(describing: iceConnectionState))")
	}

	public func peerConnection(id: P2PConnectionID, didChangeICEGatheringState iceGatheringState: ICEGatheringState) {
		loggerGlobal.warning("NOT IMPLEMENTED: \(#function), IGNORED \(String(describing: iceGatheringState))")
	}

	public func peerConnection(id: P2PConnectionID, didGenerateICECandidate iceCandidate: WebRTCICECandidate) {
		loggerGlobal.warning("NOT IMPLEMENTED: \(#function), IGNORED")
	}

	public func peerConnection(id: P2PConnectionID, didRemoveICECandidates iceCandidates: [WebRTCICECandidate]) {
		loggerGlobal.warning("NOT IMPLEMENTED: \(#function), IGNORED #\(iceCandidates.count) ICECanidates.")
	}

	public func peerConnection(id: P2PConnectionID, didAddStreamWithID streamID: String) {
		loggerGlobal.warning("NOT IMPLEMENTED: \(#function), IGNORED streamID: \(String(describing: streamID))")
	}

	public func peerConnection(id: P2PConnectionID, didRemoveStreamWithID streamID: String) {
		loggerGlobal.warning("NOT IMPLEMENTED: \(#function), IGNORED streamID: \(String(describing: streamID))")
	}

	public func peerConnection(id: P2PConnectionID, didOpenDataChannel labelledID: DataChannelLabelledID) {
		loggerGlobal.warning("NOT IMPLEMENTED: \(#function), IGNORED labelledID: \(String(describing: labelledID))")
	}

	public func peerConnectionShouldNegotiate(id: P2PConnectionID) {
		loggerGlobal.warning("NOT IMPLEMENTED: \(#function)")
	}
}
