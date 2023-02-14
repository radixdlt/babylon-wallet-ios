import Foundation
import P2PModels
import WebRTC

extension DataChannelState {
	internal init(rtcDataChannelState: RTCDataChannelState) throws {
		switch rtcDataChannelState {
		case .connecting: self = .connecting
		case .open: self = .open
		case .closing: self = .closing
		case .closed: self = .closed
		@unknown default:
			throw ConverseError.webRTC(.failedToBridgeRTCDataChannelState(unknownCase: String(describing: rtcDataChannelState)))
		}
	}
}
