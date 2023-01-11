import Foundation
import P2PModels
import WebRTC

extension WebRTCDataChannelConfig {
	func rtc() -> RTCDataChannelConfiguration {
		let config = RTCDataChannelConfiguration()
		config.isNegotiated = self.isNegotiated
		config.isOrdered = self.isOrdered
		config.maxPacketLifeTime = self.maxPacketLifeTime
		config.maxRetransmits = self.maxRetransmits
		config.channelId = self.channelId.rawValue
		return config
	}
}

extension WebRTCSDPSemantics {
	func rtc() -> RTCSdpSemantics {
		switch self {
		case .unifiedPlan: return .unifiedPlan
		case .planB: return .planB
		}
	}
}

extension WebRTCContinualGatheringPolicy {
	func rtc() -> RTCContinualGatheringPolicy {
		switch self {
		case .gatherOnce: return .gatherOnce
		case .gatherContinually: return .gatherContinually
		}
	}
}

extension RTCDataChannel {
	var labelledChannelID: DataChannelLabelledID {
		.init(channelId: .init(self.channelId), channelLabel: .init(self.label))
	}
}
