import Prelude

// MARK: - PeerConnection
protocol PeerConnection: Sendable {
	func setLocalDescription(_ description: Either<RTCPrimitive.Offer, RTCPrimitive.Answer>) async throws
	func setRemoteDescription(_ description: Either<RTCPrimitive.Offer, RTCPrimitive.Answer>) async throws

	/// Generate a SDP answer.
	func createLocalAnswer() async throws -> RTCPrimitive.Answer

	/// Generate a SDP offer.
	func createLocalOffer() async throws -> RTCPrimitive.Offer

	/// Provide a remote candidate to the ICE Agent.
	func addRemoteICECandidate(_ candidate: RTCPrimitive.ICECandidate) async throws

	/// Create a new data channel with the given label and configuration.
	func createDataChannel() throws -> DataChannelClient

	func close()
}

// MARK: - PeerConnectionDelegate
protocol PeerConnectionDelegate: Sendable {
	var onNegotiationNeeded: AsyncStream<Void> { get }
	var onIceConnectionState: AsyncStream<ICEConnectionState> { get }
	var onSignalingState: AsyncStream<SignalingState> { get }
	var onGeneratedICECandidate: AsyncStream<RTCPrimitive.ICECandidate> { get }

	func cancel()
}

public enum ICEConnectionState: String, Sendable {
        case new
        case checking
        case connected
        case completed
        case failed
        case disconnected
        case closed
}

// MARK: - SignalingState
public enum SignalingState: String, Sendable, Hashable, Codable {
	case closed, stable, haveLocalOffer, haveLocalPrAnswer, haveRemoteOffer, haveRemotePrAnswer
}
