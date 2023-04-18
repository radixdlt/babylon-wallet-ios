import AsyncExtensions
import Prelude
import RadixConnectModels

// MARK: - PeerConnectionClient
/// A client that manages a given PeerConnection and its related DataChannel.
public struct PeerConnectionClient: Sendable {
	typealias ID = PeerConnectionID
	let id: ID
	private let iceConnectionStateSubject: AsyncCurrentValueSubject<ICEConnectionState>

	var iceConnectionStates: AnyAsyncSequence<ICEConnectionState> {
		iceConnectionStateSubject.share().eraseToAnyAsyncSequence()
	}

	private let peerConnection: PeerConnection
	private let delegate: PeerConnectionDelegate
	private let dataChannelClient: DataChannelClient

	init(id: ID, peerConnection: PeerConnection, delegate: PeerConnectionDelegate) throws {
		self.id = id
		self.peerConnection = peerConnection
		self.delegate = delegate
		self.dataChannelClient = try peerConnection.createDataChannel()
		let iceConnectionStateSubject = AsyncCurrentValueSubject<ICEConnectionState>(.new)
		self.iceConnectionStateSubject = iceConnectionStateSubject
		Task {
			for try await connectionUpdate in delegate.onIceConnectionState {
				loggerGlobal.info("Ice connection state: \(connectionUpdate)")
				iceConnectionStateSubject.send(connectionUpdate)
			}
		}
	}
}

extension PeerConnectionClient {
	func cancel() async {
		delegate.cancel()
		await dataChannelClient.cancel()
		peerConnection.close()
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

	func setRemoteOffer(_ offer: RTCPrimitive.Offer) async throws {
		try await peerConnection.setRemoteDescription(.left(offer))
	}

	func setRemoteAnswer(_ answer: RTCPrimitive.Answer) async throws {
		try await peerConnection.setRemoteDescription(.right(answer))
	}

	func setRemoteICECandidate(_ candidate: RTCPrimitive.ICECandidate) async throws {
		try await peerConnection.addRemoteICECandidate(candidate)
	}
}

extension PeerConnectionClient {
	func sendData(_ data: Data) async throws {
		#if DEBUG
		loggerGlobal.trace("Sending data, json:\n\n\(String(describing: data.prettyPrintedJSONString))\n\n")
		#endif // DEBUG
		try await dataChannelClient.sendMessage(data)
	}

	func receivedMessagesStream() async -> AnyAsyncSequence<Result<DataChannelClient.AssembledMessage, Error>> {
		await dataChannelClient.IncomingAssembledMessages
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
