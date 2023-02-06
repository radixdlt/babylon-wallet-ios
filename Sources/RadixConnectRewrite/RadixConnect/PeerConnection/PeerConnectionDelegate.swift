// MARK: - PeerConnection
protocol PeerConnection: Sendable {
        func setLocalOffer(_ offer: RTCPrimitive.Offer) async throws

        func setRemoteAnswer(_ answer: RTCPrimitive.Answer) async throws

        /// Generate an SDP offer.
        func createLocalOffer() async throws -> RTCPrimitive.Offer

        /// Generate an SDP answer.
        func createLocalAnswer() async throws -> RTCPrimitive.Answer

        /// Provide a remote candidate to the ICE Agent.
        func addRemoteICECandidate(_ candidate: RTCPrimitive.ICECandidate) async throws

        /// Create a new data channel with the given label and configuration.
        func createDataChannel() throws -> DataChannelClient
}

protocol PeerConnectionDelegate: Sendable {
        var onNegotiationNeeded: AsyncStream<Void> { get }
        var onIceConnectionState: AsyncStream<ICEConnectionState> { get }
        var onSignalingState: AsyncStream<SignalingState> { get }
        var onGeneratedICECandidate: AsyncStream<RTCPrimitive.ICECandidate> { get }
}
