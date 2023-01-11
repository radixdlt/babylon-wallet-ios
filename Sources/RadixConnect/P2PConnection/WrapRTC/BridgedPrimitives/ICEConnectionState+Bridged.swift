import Foundation
import P2PModels
import WebRTC

internal extension ICEConnectionState {
	init(rtcIceConnectionState: RTCIceConnectionState) throws {
		switch rtcIceConnectionState {
		case .new: self = .new
		case .checking: self = .checking
		case .connected: self = .connected
		case .completed: self = .completed
		case .failed: self = .failed
		case .disconnected: self = .disconnected
		case .closed: self = .closed
		case .count:
			throw ConverseError.WebRTC.failedToBridgeRTCIceConnectionState(unknownCase: String(describing: rtcIceConnectionState))
		@unknown default:
			throw ConverseError.WebRTC.failedToBridgeRTCIceConnectionState(unknownCase: String(describing: rtcIceConnectionState))
		}
	}
}
