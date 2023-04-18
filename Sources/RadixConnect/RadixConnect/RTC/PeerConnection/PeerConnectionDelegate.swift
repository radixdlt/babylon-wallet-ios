import Prelude

// MARK: - PeerConnection
protocol PeerConnection: Sendable {
	func setLocalDescription(_ description: Either<RTCPrimitive.Offer, RTCPrimitive.Answer>) async throws
	func setRemoteDescription(_ description: Either<RTCPrimitive.Offer, RTCPrimitive.Answer>) async throws
	func createLocalAnswer() async throws -> RTCPrimitive.Answer
	func createLocalOffer() async throws -> RTCPrimitive.Offer
	func addRemoteICECandidate(_ candidate: RTCPrimitive.ICECandidate) async throws
	func createDataChannel() throws -> DataChannelClient
	func close()
}

// MARK: - PeerConnectionDelegate
protocol PeerConnectionDelegate: Sendable {
	var onNegotiationNeeded: AsyncStream<Void> { get }

	var onIceConnectionState: AnyAsyncSequence<ICEConnectionState> { get }

	var onSignalingState: AsyncStream<SignalingState> { get }
	var onGeneratedICECandidate: AsyncStream<RTCPrimitive.ICECandidate> { get }

	func cancel()
}

// MARK: - ICEConnectionState
public enum ICEConnectionState: String, Sendable {
	case new, checking, connected, completed, failed, disconnected, closed
}

// MARK: - SignalingState
public enum SignalingState: String, Sendable, Hashable, Codable {
	case closed, stable, haveLocalOffer, haveLocalPrAnswer, haveRemoteOffer, haveRemotePrAnswer
}
