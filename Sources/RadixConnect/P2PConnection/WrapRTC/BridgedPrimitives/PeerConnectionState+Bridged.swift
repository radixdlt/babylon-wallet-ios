import Foundation
import P2PModels
import WebRTC

extension PeerConnectionState {
	internal init(rtcPeerConnectionState: RTCPeerConnectionState) throws {
		switch rtcPeerConnectionState {
		case .new: self = .new
		case .connecting: self = .connecting
		case .connected: self = .connected
		case .closed: self = .closed
		case .disconnected: self = .disconnected
		case .failed: self = .failed
		@unknown default:
			throw ConverseError.webRTC(.failedToBridgeRTCPeerConnectionState(unknownCase: String(describing: rtcPeerConnectionState)))
		}
	}
}
