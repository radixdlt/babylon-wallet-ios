import Foundation

// MARK: - WebRTCEvent
public enum WebRTCEvent: Sendable, Hashable, Codable, CustomStringConvertible {
	case peerConnection(PeerConnectionEvent)
	case dataChannel(DataChannelEvent)
}

extension WebRTCEvent {
	public var description: String {
		switch self {
		case let .peerConnection(event): return "peerConnection(\(event))"
		case let .dataChannel(event): return "dataChannel(\(event))"
		}
	}
}

// MARK: WebRTCEvent.PeerConnectionEvent
extension WebRTCEvent {
	public enum PeerConnectionEvent: Sendable, Hashable, Codable, CustomStringConvertible {
		case didAddStream(id: String)
		case didRemoveStream(id: String)
		case didOpenDataChannel(label: String)
		case didChangePeerConnectionState(PeerConnectionState)
		case didChangeSignalingState(SignalingState)
		case didRemoveICECandidates([WebRTCICECandidate])
		case didGenerateICECandidate(WebRTCICECandidate)
		case didChangeICEGatheringState(ICEGatheringState)
		case didChangeICEConnectionState(ICEConnectionState)

		case shouldNegotiate
	}
}

// MARK: WebRTCEvent.DataChannelEvent
extension WebRTCEvent {
	public enum DataChannelEvent: Sendable, Hashable, Codable, CustomStringConvertible {
		case didChangeState(DataChannelState, channelLabel: String, channelId: Int32)

		case didReceiveMessage(Data, channelLabel: String, channelId: Int32)
	}
}

extension WebRTCEvent.DataChannelEvent {
	public var description: String {
		switch self {
		case let .didChangeState(newState, channelLabel, channelId): return "didChangeState(\(newState), channel: '\(channelLabel)', channelId: '\(channelId)')"
		case let .didReceiveMessage(msg, channelLabel, channelId): return "didReceiveMessage(#\(msg.count) bytes, channel: '\(channelLabel)', channelId: '\(channelId)')"
		}
	}
}

extension WebRTCEvent.PeerConnectionEvent {
	public var description: String {
		switch self {
		case let .didAddStream(id): return "didAddStream(id: \(id))"
		case let .didRemoveStream(id): return "didRemoveStream(id: \(id))"
		case let .didChangePeerConnectionState(state): return "didChangePeerConnectionState(\(state))"
		case let .didOpenDataChannel(id): return "didOpenDataChannel(id: \(id))"
		case let .didChangeSignalingState(state): return "didChangeSignalingState(\(state))"
		case let .didRemoveICECandidates(candidates): return "didRemoveICECandidates(#\(candidates.count) many)"
		case .didGenerateICECandidate: return "didGenerateICECandidate"
		case let .didChangeICEGatheringState(state): return "didChangeICEGatheringState(\(state))"
		case let .didChangeICEConnectionState(state): return "didChangeICEConnectionState(\(state))"
		case .shouldNegotiate: return "shouldNegotiate"
		}
	}
}
