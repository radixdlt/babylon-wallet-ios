import AsyncExtensions
import Foundation


public typealias PeerConnectionId = ClientID

// MARK: - PeerConnectionClient
public struct PeerConnectionClient: Sendable {

	let id: PeerConnectionId
	private let peerConnection: PeerConnection
	private let delegate: PeerConnectionDelegate
	private let dataChannelClient: DataChannelClient

        let onIceConnectionState: AnyAsyncSequence<ICEConnectionState>

	init(id: PeerConnectionId, peerConnection: PeerConnection, delegate: PeerConnectionDelegate) throws {
		self.id = id
		self.peerConnection = peerConnection
		self.delegate = delegate
		self.dataChannelClient = try peerConnection.createDataChannel()

                self.onIceConnectionState = delegate
                        .onIceConnectionState
                        .logInfo("Ice connection state: %@")
                        .eraseToAnyAsyncSequence()
                        .share()
                        .eraseToAnyAsyncSequence()

        }

	func onRemoteOffer(_ answer: RTCPrimitive.Offer) async throws {
		try await peerConnection.setRemoteOffer(answer)
	}

        func onRemoteAnswer(_ answer: RTCPrimitive.Answer) async throws {
                try await peerConnection.setRemoteAnswer(answer)
        }

	func createAnswer() async throws -> RTCPrimitive.Answer {
		let answer = try await peerConnection.createLocalAnswer()
		try await peerConnection.setLocalAnswer(answer)
		return answer
	}

        func createOffer() async throws -> RTCPrimitive.Offer {
                let offer = try await peerConnection.createOffer()
                try await peerConnection.setLocalOffer(offer)
                return offer
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

	var onSignalingState: AsyncStream<SignalingState> {
		delegate.onSignalingState
	}

	var onGeneratedICECandidate: AsyncStream<RTCPrimitive.ICECandidate> {
		delegate.onGeneratedICECandidate
	}
}
