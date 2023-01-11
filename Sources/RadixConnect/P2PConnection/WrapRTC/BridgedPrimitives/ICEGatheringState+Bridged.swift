import Foundation
import P2PModels
import WebRTC

internal extension ICEGatheringState {
	init(rtcIceGatheringState: RTCIceGatheringState) throws {
		switch rtcIceGatheringState {
		case .complete: self = .complete
		case .gathering: self = .gathering
		case .new: self = .new
		@unknown default:
			throw ConverseError.webRTC(.failedToBridgeRTCIceGatheringState(unknownCase: String(describing: rtcIceGatheringState)))
		}
	}
}
