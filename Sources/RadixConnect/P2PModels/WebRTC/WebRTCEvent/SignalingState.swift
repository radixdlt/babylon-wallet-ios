import Foundation

// MARK: - SignalingState
/// The read-only signalingState property on the RTCPeerConnection interface returns
///  an enum describing the state of the signaling process on the local end of the
///  connection while connecting or reconnecting to another peer. See Signaling in
///  Lifetime of a WebRTC session for more details about the signaling process.
///
/// Because the signaling process is a state machine, being able to verify that
/// your code is in the expected state when messages arrive can help avoid unexpected
/// and avoidable failures. For example, if you receive an answer while the
/// signalingState isn't "have-local-offer", you know that something is wrong,
/// since you should only receive answers after creating an offer but before an answer
/// has been received and passed into RTCPeerConnection.setLocalDescription().
/// Your code will be more reliable if you watch for mismatched states like this and handle them gracefully.
///
/// This value may also be useful during debugging, for example.
///
/// In addition, when the value of this property changes, a signalingstatechange event is sent to the RTCPeerConnection instance.
///
/// For more info, [see docs][docs]
///
/// [docs]: https://developer.mozilla.org/en-US/docs/Web/API/RTCPeerConnection/signalingState
///
public enum SignalingState: String, Sendable, Hashable, Codable, CustomStringConvertible {
	/// There is no ongoing exchange of offer and answer underway. This may mean that
	/// the RTCPeerConnection object is new, in which case both the localDescription
	/// and remoteDescription are null; it may also mean that negotiation is complete
	/// and a connection has been established.
	case stable

	/// The local peer has called RTCPeerConnection.setLocalDescription(), passing
	/// in SDP representing an offer (usually created by calling
	/// RTCPeerConnection.createOffer()), and the offer has been applied successfully.
	case haveLocalOffer

	/// The remote peer has created an offer and used the signaling server to deliver
	/// it to the local peer, which has set the offer as the remote description
	/// by calling RTCPeerConnection.setRemoteDescription().
	case haveRemoteOffer

	/// The offer sent by the remote peer has been applied and an answer has been
	/// created (usually by calling RTCPeerConnection.createAnswer()) and applied
	/// by calling RTCPeerConnection.setLocalDescription(). This provisional answer
	/// describes the supported media formats and so forth, but may not have a
	/// complete set of ICE candidates included. Further candidates will be delivered
	/// separately later.
	case haveLocalPrAnswer

	/// A provisional answer has been received and successfully applied in response
	/// to an offer previously sent and established by calling setLocalDescription().
	case haveRemotePrAnswer

	/// The RTCPeerConnection has been closed.
	case closed
}

public extension SignalingState {
	var description: String {
		rawValue
	}
}
