import Foundation

/// The read-only connectionState property of the RTCPeerConnection interface
/// indicates the current state of the peer connection by returning one of
/// the following string values: new, connecting, connected, disconnected, failed, or closed.
///
/// This state essentially represents the aggregate state of all ICE transports (which are of type RTCIceTransport or RTCDtlsTransport) being used by the connection.
///
/// When this property's value changes, a connectionstatechange event is sent to the RTCPeerConnection instance.
///
/// For more info, [read docs][docs]
///
/// [docs]: https://developer.mozilla.org/en-US/docs/Web/API/RTCPeerConnection/connectionState
///
public enum PeerConnectionState: String, Sendable, Hashable, Codable, CustomStringConvertible {
	/// **At least one** of the connection's ICE transports (RTCIceTransport or RTCDtlsTransport objects)
	/// is in the new `state`, and none of them are in one of the following states:
	/// `connecting`, `checking`, `failed`, `disconnected`, or all of the connection's transports are
	/// in the `closed` state.
	case new

	/// **One or more** of the ICE transports are currently in the process of establishing
	/// a connection; that is, their iceConnectionState is either `checking` or `connected`,
	/// and no transports are in the `failed` state.
	case connecting

	/// **Every** ICE transport used by the connection is either in use (state `connected` or `completed`)
	/// or is `closed` (state `closed`); in addition, at least one transport is either `connected` or `completed`.
	case connected

	/// **At least one** of the ICE transports for the connection is in the `disconnected` state and
	/// none of the other transports are in the state `failed`, `connecting`, or `checking`.
	case disconnected

	/// **One or more** of the ICE transports on the connection is in the `failed` state.
	case failed

	/// The RTCPeerConnection is `closed`.
	case closed
}
