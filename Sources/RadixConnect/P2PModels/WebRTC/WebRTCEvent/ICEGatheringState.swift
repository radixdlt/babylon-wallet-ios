import Foundation

// MARK: - ICEGatheringState
/// The read-only property RTCPeerConnection.iceGatheringState returns
/// an enum that describes the connection's ICE gathering state.
///
/// This lets you detect, for example, when collection of ICE candidates has finished.
///
/// For more info, [read docs][docs]
///
/// [docs]: https://developer.mozilla.org/en-US/docs/Web/API/RTCPeerConnection/iceGatheringState
///
public enum ICEGatheringState: String, Sendable, Hashable, Codable, CustomStringConvertible {
	/// The peer connection was just created and hasn't done any networking yet.
	case new

	/// The ICE agent is in the process of gathering candidates for the connection.
	case complete

	/// The ICE agent has finished gathering candidates. If something happens
	/// that requires collecting new candidates, such as a new interface
	/// being added or the addition of a new ICE server, the state will
	/// revert to gathering to gather those candidates.
	case gathering
}

public extension ICEGatheringState {
	var description: String {
		rawValue
	}
}
