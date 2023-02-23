// MARK: - PeerConnection
protocol PeerConnection: Sendable {
	func setLocalAnswer(_ answer: RTCPrimitive.Answer) async throws

	func setRemoteOffer(_ offer: RTCPrimitive.Offer) async throws

        func setRemoteAnswer(_ answer: RTCPrimitive.Answer) async throws

	/// Generate an SDP answer.
	func createLocalAnswer() async throws -> RTCPrimitive.Answer

        func createOffer() async throws -> RTCPrimitive.Offer

        func setLocalOffer(_ offer: RTCPrimitive.Offer) async throws

	/// Provide a remote candidate to the ICE Agent.
	func addRemoteICECandidate(_ candidate: RTCPrimitive.ICECandidate) async throws

	/// Create a new data channel with the given label and configuration.
	func createDataChannel() throws -> DataChannelClient
}

// MARK: - PeerConnectionDelegate
protocol PeerConnectionDelegate: Sendable {
	var onNegotiationNeeded: AsyncStream<Void> { get }
	var onIceConnectionState: AsyncStream<ICEConnectionState> { get }
	var onSignalingState: AsyncStream<SignalingState> { get }
	var onGeneratedICECandidate: AsyncStream<RTCPrimitive.ICECandidate> { get }
}

// MARK: - SignalingState
public enum SignalingState: String, Sendable, Hashable, Codable {
	case closed, stable, haveLocalOffer, haveLocalPrAnswer, haveRemoteOffer, haveRemotePrAnswer
}
