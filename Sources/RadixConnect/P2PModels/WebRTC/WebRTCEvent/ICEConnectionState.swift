import Foundation

// MARK: - ICEConnectionState
/// The read-only property RTCPeerConnection.iceConnectionState returns an enum
///  which state of the ICE agent associated with the RTCPeerConnection:
///  new, checking, connected, completed, failed, disconnected, and closed.
///
/// It describes the current state of the ICE agent and its connection to the
/// ICE server; that is, the STUN or TURN server.
///
/// For more info, [read docs][docs].
///
/// [docs]: https://developer.mozilla.org/en-US/docs/Web/API/RTCPeerConnection/iceConnectionState
public enum ICEConnectionState: String, Sendable, Hashable, Codable, CustomStringConvertible {
	/// The ICE agent is gathering addresses or is waiting to be given remote
	/// candidates through calls to RTCPeerConnection.addIceCandidate() (or both).
	case new

	/// The ICE agent has been given one or more remote candidates and is checking
	///  pairs of local and remote candidates against one another to try to find
	///  a compatible match, but has not yet found a pair which will allow the
	///  peer connection to be made. It is possible that gathering of candidates
	///   is also still underway.
	case checking

	/// A usable pairing of local and remote candidates has been found for all components of the connection, and the connection has been established. It is possible that gathering is still underway, and it is also possible that the ICE agent is still checking candidates against one another looking for a better connection to use.
	case connected

	/// The ICE agent has finished gathering candidates, has checked all
	/// pairs against one another, and has found a connection for all components.
	case completed

	/// The ICE candidate has checked all candidates pairs against one another
	/// and has failed to find compatible matches for all components of
	/// the connection. It is, however, possible that the ICE agent did
	/// find compatible connections for some components.
	case failed

	/// Checks to ensure that components are still connected failed for at least
	/// one component of the RTCPeerConnection. This is a less stringent test
	/// than failed and may trigger intermittently and resolve just as
	/// spontaneously on less reliable networks, or during temporary
	/// disconnections. When the problem resolves, the connection may
	/// return to the connected state.
	case disconnected

	/// The ICE agent for this RTCPeerConnection has shut down and is no longer handling requests.
	case closed
}

extension ICEConnectionState {
	public var description: String {
		rawValue
	}
}
