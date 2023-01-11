import Foundation

// MARK: - ConnectionStatus
/// The canonical type for connection status of a peer, driven by DataChannelState (`RTCDataChannel`s property `readyState`) or by the `RTCPeerConnection`'s `RTCPeerConnectinState`.
public enum ConnectionStatus: String, Sendable, Hashable, Codable, CustomStringConvertible {
	/// **At least one** of the connection's ICE transports (RTCIceTransport or RTCDtlsTransport objects)
	/// is in the new `state`, and none of them are in one of the following states:
	/// `connecting`, `checking`, `failed`, `disconnected`, or all of the connection's transports are
	/// in the `closed` state.
	case new

	/// DataChannel's `readyState` is `connecting` or `PeerConnectionState` is `connecting`,
	/// which means:
	///
	/// **One or more** of the ICE transports are currently in the process of establishing
	/// a connection; that is, their iceConnectionState is either `checking` or `connected`,
	/// and no transports are in the `failed` state.
	case connecting

	/// DataChannel's `readyState` is `open` or `PeerConnectionState` is `connecting`,
	/// which means:
	///
	/// **Every** ICE transport used by the connection is either in use (state `connected` or `completed`)
	/// or is `closed` (state `closed`); in addition, at least one transport is either `connected` or `completed`.
	case connected

	case closed
	case closing
	case disconnected
	case failed
}

public extension ConnectionStatus {
	init?(iceConnectionState: ICEConnectionState) {
		switch iceConnectionState {
		case .new: self = .new
		case .disconnected: self = .disconnected
		case .failed: self = .failed
		case .closed: self = .closed
		case .connected: self = .connected
		case .checking: return nil
		case .completed: return nil
		}
	}

	init(peerConnectionState: PeerConnectionState) {
		switch peerConnectionState {
		case .new: self = .new
		case .connecting: self = .connecting
		case .disconnected: self = .disconnected
		case .failed: self = .failed
		case .closed: self = .closed
		case .connected: self = .connected
		}
	}

	init(dataChannelState: DataChannelState) {
		switch dataChannelState {
		case .open:
			self = .connected
		case .closed:
			self = .closed
		case .connecting:
			self = .connecting
		case .closing:
			self = .closing
		}
	}
}
