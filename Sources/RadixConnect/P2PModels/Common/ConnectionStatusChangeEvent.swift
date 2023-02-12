import Foundation

// MARK: - ConnectionStatusChangeEvent
public struct ConnectionStatusChangeEvent: Sendable, Hashable, CustomStringConvertible {
	public let connectionID: P2PConnectionID
	public let connectionStatus: ConnectionStatus
	public let source: Source

	public init(
		connectionID: P2PConnectionID,
		connectionStatus: ConnectionStatus,
		source: Source
	) {
		self.connectionID = connectionID
		self.connectionStatus = connectionStatus
		self.source = source
	}
}

// MARK: ConnectionStatusChangeEvent.Source
extension ConnectionStatusChangeEvent {
	public enum Source: Sendable, Hashable, CustomStringConvertible {
		case user
		case dataChannelReadyState(channelID: DataChannelLabelledID, dataChannelReadyState: DataChannelState)
		case iceConnection
		case peerConnection

		var dataChannelReadyState: (channelID: DataChannelLabelledID, dataChannelReadyState: DataChannelState)? {
			guard case let .dataChannelReadyState(channelID, dataChannelReadyState) = self else {
				return nil
			}
			return (channelID, dataChannelReadyState)
		}
	}
}

extension ConnectionStatusChangeEvent {
	public var description: String {
		"\(connectionStatus), source: \(source), id: \(connectionID)"
	}
}

extension ConnectionStatusChangeEvent.Source {
	public var description: String {
		switch self {
		case .user: return "user"
		case let .dataChannelReadyState(channelID, dataChannelReadyState):
			return "dataChannelReadyState(channelID: \(channelID), dataChannelReadyState: \(dataChannelReadyState)"
		case .iceConnection:
			return "iceConnection"
		case .peerConnection:
			return "peerConnection"
		}
	}
}
