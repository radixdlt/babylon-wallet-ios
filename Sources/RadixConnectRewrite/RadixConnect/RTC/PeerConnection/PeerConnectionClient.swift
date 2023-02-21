import AsyncExtensions
import Foundation

// MARK: - PeerConnectionClient
struct PeerConnectionClient {
        typealias ID = ClientID

	let id: ID
	private let peerConnection: PeerConnection
	private let delegate: PeerConnectionDelegate
	private let dataChannelClient: DataChannelClient

	init(id: ID, peerConnection: PeerConnection, delegate: PeerConnectionDelegate) throws {
		self.id = id
		self.peerConnection = peerConnection
		self.delegate = delegate
		self.dataChannelClient = try peerConnection.createDataChannel()
	}

	func onRemoteOffer(_ answer: RTCPrimitive.Offer) async throws {
		try await peerConnection.setRemoteOffer(answer)
	}

	func createAnswer() async throws -> RTCPrimitive.Answer {
		let answer = try await peerConnection.createLocalAnswer()
		try await peerConnection.setLocalAnswer(answer)
		return answer
	}

	func onRemoteICECandidate(_ candidate: RTCPrimitive.ICECandidate) async throws {
		try await peerConnection.addRemoteICECandidate(candidate)
	}
}

extension PeerConnectionClient {
	func sendData(_ data: Data) async throws {
		try await dataChannelClient.sendMessage(data)
	}

	func receivedMessagesStream() async -> AnyAsyncSequence<Result<DataChannelAssembledMessage, Error>> {
		await dataChannelClient.incommingAssembledMessages
	}
}

extension PeerConnectionClient {
	var onNegotiationNeeded: AsyncStream<Void> {
		delegate.onNegotiationNeeded
	}

	var onIceConnectionState: AsyncStream<ICEConnectionState> {
		delegate.onIceConnectionState
	}

	var onSignalingState: AsyncStream<SignalingState> {
		delegate.onSignalingState
	}

	var onGeneratedICECandidate: AsyncStream<RTCPrimitive.ICECandidate> {
		delegate.onGeneratedICECandidate
	}
}
