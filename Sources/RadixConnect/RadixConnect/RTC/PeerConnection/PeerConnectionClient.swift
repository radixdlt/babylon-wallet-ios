import AsyncExtensions
import Foundation
import RadixConnectModels

// MARK: - PeerConnectionClient
/// A client that manages a given PeerConnection and its related DataChannel.
public struct PeerConnectionClient: Sendable {
	let id: PeerConnectionID
	private let peerConnection: PeerConnection
	private let delegate: PeerConnectionDelegate
	private let dataChannelClient: DataChannelClient

	let iceConnectionStates: AnyAsyncSequence<ICEConnectionState>

	init(id: PeerConnectionID, peerConnection: PeerConnection, delegate: PeerConnectionDelegate) throws {
		self.id = id
		self.peerConnection = peerConnection
		self.delegate = delegate
		self.dataChannelClient = try peerConnection.createDataChannel()

		self.iceConnectionStates = delegate
			.onIceConnectionState
			.logInfo("Ice connection state: %@")
			.eraseToAnyAsyncSequence()
			.share()
			.eraseToAnyAsyncSequence()
	}

	func setRemoteOffer(_ offer: RTCPrimitive.Offer) async throws {
		try await peerConnection.setRemoteDescription(.left(offer))
	}

	func setRemoteAnswer(_ answer: RTCPrimitive.Answer) async throws {
		try await peerConnection.setRemoteDescription(.right(answer))
	}

	func createAnswer() async throws -> RTCPrimitive.Answer {
		let answer = try await peerConnection.createLocalAnswer()
		try await peerConnection.setLocalDescription(.right(answer))
		return answer
	}

	func createLocalOffer() async throws -> RTCPrimitive.Offer {
		let offer = try await peerConnection.createLocalOffer()
		try await peerConnection.setLocalDescription(.left(offer))
		return offer
	}

	func setRemoteICECandidate(_ candidate: RTCPrimitive.ICECandidate) async throws {
		try await peerConnection.addRemoteICECandidate(candidate)
	}

	func cancel() async {
		delegate.cancel()
		await dataChannelClient.cancel()
		peerConnection.close()
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

	var onSignalingState: AsyncStream<SignalingState> {
		delegate.onSignalingState
	}

	var onGeneratedICECandidate: AsyncStream<RTCPrimitive.ICECandidate> {
		delegate.onGeneratedICECandidate
	}
}
