import Foundation
import P2PModels
import WebRTC

extension SignalingState {
	internal init(rtcSignalingState: RTCSignalingState) throws {
		switch rtcSignalingState {
		case .stable: self = .stable
		case .haveLocalOffer: self = .haveLocalOffer
		case .haveRemoteOffer: self = .haveRemoteOffer
		case .haveLocalPrAnswer: self = .haveLocalPrAnswer
		case .haveRemotePrAnswer: self = .haveRemotePrAnswer
		case .closed: self = .closed
		@unknown default:
			throw ConverseError.webRTC(.failedToBridgeRTCSignalingState(unknownCase: String(describing: rtcSignalingState)))
		}
	}
}
