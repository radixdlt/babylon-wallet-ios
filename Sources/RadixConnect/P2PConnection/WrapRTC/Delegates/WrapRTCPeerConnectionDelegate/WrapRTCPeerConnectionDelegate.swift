import Foundation
import P2PModels
import WebRTC

// MARK: - WrapPeerConnectionWithDataChannel.WrapRTCPeerConnectionDelegate
extension WrapPeerConnectionWithDataChannel {
	final class WrapRTCPeerConnectionDelegate: NSObject, RTCPeerConnectionDelegate {
		let connectionID: P2PConnectionID
		weak var delegate: WebRTCPeerConnectionDelegate?

		init(
			connectionID: P2PConnectionID,
			delegate: WebRTCPeerConnectionDelegate
		) {
			self.connectionID = connectionID
			self.delegate = delegate
			super.init()
		}
	}
}

// MARK: RTCPeerConnectionDelegate impl
extension WrapPeerConnectionWithDataChannel.WrapRTCPeerConnectionDelegate {
	func peerConnection(
		_ peerConnection: RTCPeerConnection,
		didChange rtcPeerConnectionState: RTCPeerConnectionState
	) {
		let ignored = "peerConnection:didChange RTCPeerConnectionState (to: \(String(describing: rtcPeerConnectionState)) IGNORED"
		guard let delegate else {
			loggerGlobal.notice("\(ignored), since delegate is nil")
			return
		}
		do {
			let peerConnectionState = try PeerConnectionState(rtcPeerConnectionState: rtcPeerConnectionState)
			loggerGlobal.debug("peerConnection:\(connectionID) didChangePeerConnectionState to: \(String(describing: peerConnectionState))")
			delegate.peerConnection(id: connectionID, didChangePeerConnectionState: peerConnectionState)
		} catch {
			loggerGlobal.error("\(ignored), since failed to bridge to `\(PeerConnectionState.self)`, failure: \(error)")
		}
	}

	func peerConnection(
		_ peerConnection: RTCPeerConnection,
		didChange rtcSignalingState: RTCSignalingState
	) {
		let ignored = "peerConnection:didChange RTCSignalingState (to: \(String(describing: rtcSignalingState)) IGNORED"
		guard let delegate else {
			loggerGlobal.notice("\(ignored), since delegate is nil")
			return
		}
		do {
			let signalingState = try SignalingState(rtcSignalingState: rtcSignalingState)
			loggerGlobal.debug("peerConnection:\(connectionID) didChangeSignalingState to: \(String(describing: signalingState))")
			delegate.peerConnection(id: connectionID, didChangeSignalingState: signalingState)
		} catch {
			loggerGlobal.error("\(ignored), since failed to bridge to `\(SignalingState.self)`, failure: \(error)")
		}
	}

	func peerConnection(
		_ peerConnection: RTCPeerConnection,
		didAdd stream: RTCMediaStream
	) {
		let ignored = "peerConnection:didAdd (stream.id: \(String(describing: stream.streamId)) IGNORED"
		guard let delegate else {
			loggerGlobal.notice("\(ignored), since delegate is nil")
			return
		}
		loggerGlobal.debug("peerConnection:\(connectionID) didAddStreamWithID: \(stream.streamId)")
		delegate.peerConnection(id: connectionID, didAddStreamWithID: stream.streamId)
	}

	func peerConnection(
		_ peerConnection: RTCPeerConnection,
		didRemove stream: RTCMediaStream
	) {
		let ignored = "peerConnection:didRemove (stream.id: \(String(describing: stream.streamId)) IGNORED"
		guard let delegate else {
			loggerGlobal.notice("\(ignored), since delegate is nil")
			return
		}
		loggerGlobal.debug("peerConnection:\(connectionID) didRemoveStreamWithID: \(stream.streamId)")
		delegate.peerConnection(id: connectionID, didRemoveStreamWithID: stream.streamId)
	}

	func peerConnectionShouldNegotiate(
		_ peerConnection: RTCPeerConnection
	) {
		let ignored = "peerConnectionShouldNegotiate IGNORED"
		guard let delegate else {
			loggerGlobal.notice("\(ignored), since delegate is nil")
			return
		}
		loggerGlobal.debug("peerConnection:\(connectionID) peerConnectionShouldNegotiate")
		delegate.peerConnectionShouldNegotiate(id: connectionID)
	}

	/// This should maybe act as the canonical indication of our connection state, since it is what is used in Googles example app and driving the UI: https://chromium.googlesource.com/external/webrtc/+/refs/heads/main/examples/objc/AppRTCMobile/ARDAppClient.m#405
	func peerConnection(
		_ peerConnection: RTCPeerConnection,
		didChange rtcIceConnectionState: RTCIceConnectionState
	) {
		let ignored = "peerConnection:didChange RTCIceConnectionState (to: \(String(describing: rtcIceConnectionState)) IGNORED"
		guard let delegate else {
			loggerGlobal.notice("\(ignored), since delegate is nil")
			return
		}
		do {
			let iceConnectionState = try ICEConnectionState(rtcIceConnectionState: rtcIceConnectionState)
			loggerGlobal.debug("peerConnection:\(connectionID) didChangeICEConnectionState to: \(String(describing: iceConnectionState))")
			delegate.peerConnection(id: connectionID, didChangeICEConnectionState: iceConnectionState)
		} catch {
			loggerGlobal.error("\(ignored), since failed to bridge to `\(ICEConnectionState.self)`, failure: \(error)")
		}
	}

	func peerConnection(
		_ peerConnection: RTCPeerConnection,
		didChange rtcIceGatheringState: RTCIceGatheringState
	) {
		let ignored = "peerConnection:didChange RTCIceGatheringState (to: \(String(describing: rtcIceGatheringState)) IGNORED"
		guard let delegate else {
			loggerGlobal.notice("\(ignored), since delegate is nil")
			return
		}
		do {
			let iceGatheringState = try ICEGatheringState(rtcIceGatheringState: rtcIceGatheringState)
			loggerGlobal.debug("peerConnection:\(connectionID) didChangeICEGatheringState to: \(String(describing: iceGatheringState))")
			delegate.peerConnection(id: connectionID, didChangeICEGatheringState: iceGatheringState)
		} catch {
			loggerGlobal.error("\(ignored), since failed to bridge to `\(ICEGatheringState.self)`, failure: \(error)")
		}
	}

	func peerConnection(
		_ peerConnection: RTCPeerConnection,
		didGenerate rtcICECandidate: RTCIceCandidate
	) {
		let ignored = "peerConnection:didGenerate RTCIceCandidate (to: \(String(describing: rtcICECandidate)) IGNORED"
		guard let delegate else {
			loggerGlobal.notice("\(ignored), since delegate is nil")
			return
		}
		let iceCandidate = WebRTCICECandidate(rtcIceCandidate: rtcICECandidate)
		loggerGlobal.debug("peerConnection:\(connectionID) didGenerateICECandidate: \(String(describing: iceCandidate))")
		delegate.peerConnection(id: connectionID, didGenerateICECandidate: iceCandidate)
	}

	func peerConnection(
		_ peerConnection: RTCPeerConnection,
		didRemove rtcICECandidates: [RTCIceCandidate]
	) {
		let ignored = "peerConnection:didRemove rtcICECandidates (count: #\(rtcICECandidates.count)) IGNORED"
		guard let delegate else {
			loggerGlobal.notice("\(ignored), since delegate is nil")
			return
		}
		let iceCandidates = rtcICECandidates.map(WebRTCICECandidate.init)
		loggerGlobal.debug("peerConnection:\(connectionID) didRemoveICECandidates (count: #\(iceCandidates.count)) ")
		delegate.peerConnection(id: connectionID, didRemoveICECandidates: iceCandidates)
	}

	func peerConnection(
		_ peerConnection: RTCPeerConnection,
		didOpen rtcDataChannel: RTCDataChannel
	) {
		let labelledChannelID = rtcDataChannel.labelledChannelID
		let ignored = "peerConnection:didOpen rtcDataChannel (labelledID: \(String(describing: labelledChannelID)) IGNORED"
		guard let delegate else {
			loggerGlobal.notice("\(ignored), since delegate is nil")
			return
		}
		loggerGlobal.debug("peerConnection:\(connectionID) didOpenDataChannel: \(String(describing: labelledChannelID))")
		delegate.peerConnection(id: connectionID, didOpenDataChannel: labelledChannelID)
	}
}
