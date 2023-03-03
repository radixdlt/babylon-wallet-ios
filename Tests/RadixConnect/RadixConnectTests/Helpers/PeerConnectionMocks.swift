import Foundation
import RadixConnectModels
import TestingPrelude
@testable import RadixConnect

// MARK: - MockPeerConnectionFactory
final class MockPeerConnectionFactory: PeerConnectionFactory {
	let clients: [PeerConnectionClient]
	init(clients: [PeerConnectionClient]) {
		self.clients = clients
	}

	func makePeerConnectionClient(for clientID: RemoteClientID) throws -> PeerConnectionClient {
		clients.first { $0.id == clientID }!
	}
}

// MARK: - MockPeerConnectionDelegate
final class MockPeerConnectionDelegate: PeerConnectionDelegate {
	func cancel() {}

	let onNegotiationNeeded: AsyncStream<Void>
	let onIceConnectionState: AsyncStream<ICEConnectionState>
	let onSignalingState: AsyncStream<SignalingState>
	let onGeneratedICECandidate: AsyncStream<RTCPrimitive.ICECandidate>

	private let onNegotiationNeededContinuation: AsyncStream<Void>.Continuation
	private let onIceConnectionStateContinuation: AsyncStream<ICEConnectionState>.Continuation
	private let onSignalingStateContinuation: AsyncStream<SignalingState>.Continuation
	private let onGeneratedICECandidateContinuation: AsyncStream<RTCPrimitive.ICECandidate>.Continuation

	init() {
		(onNegotiationNeeded, onNegotiationNeededContinuation) = AsyncStream<Void>.streamWithContinuation()
		(onIceConnectionState, onIceConnectionStateContinuation) = AsyncStream<ICEConnectionState>.streamWithContinuation()
		(onSignalingState, onSignalingStateContinuation) = AsyncStream<SignalingState>.streamWithContinuation()
		(onGeneratedICECandidate, onGeneratedICECandidateContinuation) = AsyncStream<RTCPrimitive.ICECandidate>.streamWithContinuation()
	}

	// MARK: - Helper API

	func sendNegotiationNeededEvent() {
		onNegotiationNeededContinuation.yield(())
	}

	func sendICEConnectionStateEvent(_ state: ICEConnectionState) {
		onIceConnectionStateContinuation.yield(state)
	}

	func generateICECandiddate(_ candidate: RTCPrimitive.ICECandidate) {
		onGeneratedICECandidateContinuation.yield(candidate)
	}

	func close() {}
}

// MARK: - MockPeerConnection
final class MockPeerConnection: PeerConnection {
        let configuredRemoteDescription: AsyncStream<Either<RTCPrimitive.Offer, RTCPrimitive.Answer>>
        let configuredLocalDescription: AsyncStream<Either<RTCPrimitive.Offer, RTCPrimitive.Answer>>
	let configuredICECandidate: AsyncStream<RTCPrimitive.ICECandidate>
	let onCreateLocalAnswer: AsyncStream<Void>
        let onCreateLocalOffer: AsyncStream<Void>

	private let configuredRemoteDescriptionContinuation: AsyncStream<Either<RTCPrimitive.Offer, RTCPrimitive.Answer>>.Continuation
	private let configuredLocalDescriptionContinuation: AsyncStream<Either<RTCPrimitive.Offer, RTCPrimitive.Answer>>.Continuation
	private let configuredICECandidateContinuation: AsyncStream<RTCPrimitive.ICECandidate>.Continuation
	private let onCreateLocalAnswerContinuation: AsyncStream<Void>.Continuation
        private let onCreateLocalOfferContinuation: AsyncStream<Void>.Continuation
	private let stubDataChannel: Result<DataChannelClient, Error>

	private var createLocalAnswerContinuation: CheckedContinuation<RTCPrimitive.Answer, any Error>?
        private var createLocalOfferContinuation: CheckedContinuation<RTCPrimitive.Offer, any Error>?
	private var setLocalDescriptionContinuation: CheckedContinuation<Void, any Error>?
        private var setRemoteDescriptionContinuation: CheckedContinuation<Void, any Error>?
	private var addICECandidateContinuation: CheckedContinuation<Void, any Error>?

	init(dataChannel: Result<DataChannelClient, Error> = .failure(NSError(domain: "test", code: 1))) {
		self.stubDataChannel = dataChannel
		(configuredRemoteDescription, configuredRemoteDescriptionContinuation) = AsyncStream.streamWithContinuation()
		(configuredLocalDescription, configuredLocalDescriptionContinuation) = AsyncStream.streamWithContinuation()
		(configuredICECandidate, configuredICECandidateContinuation) = AsyncStream.streamWithContinuation()
		(onCreateLocalAnswer, onCreateLocalAnswerContinuation) = AsyncStream.streamWithContinuation()
                (onCreateLocalOffer, onCreateLocalOfferContinuation) = AsyncStream.streamWithContinuation()
	}

        func close() {}

        func setLocalDescription(_ description: Either<RTCPrimitive.Offer, RTCPrimitive.Answer>) async throws {
                configuredLocalDescriptionContinuation.yield(description)
                return try await withCheckedThrowingContinuation { continuation in
                        setLocalDescriptionContinuation = continuation
                }
        }

        func setRemoteDescription(_ description: Either<RTCPrimitive.Offer, RTCPrimitive.Answer>) async throws {
                configuredRemoteDescriptionContinuation.yield(description)
                return try await withCheckedThrowingContinuation { continuation in
                        setRemoteDescriptionContinuation = continuation
                }
        }

        func createLocalOffer() async throws -> RTCPrimitive.Offer {
                onCreateLocalOfferContinuation.yield(())
                return try await withCheckedThrowingContinuation { continuation in
                        createLocalOfferContinuation = continuation
                }
        }

	func createLocalAnswer() async throws -> RTCPrimitive.Answer {
		onCreateLocalAnswerContinuation.yield(())
		return try await withCheckedThrowingContinuation { continuation in
                        createLocalAnswerContinuation = continuation
		}
	}

	func addRemoteICECandidate(_ candidate: RTCPrimitive.ICECandidate) async throws {
		configuredICECandidateContinuation.yield(candidate)
		return try await withCheckedThrowingContinuation { continuation in
			addICECandidateContinuation = continuation
		}
	}

	func createDataChannel() throws -> DataChannelClient {
		try stubDataChannel.get()
	}

	// MARK: - Helper API

        func onOfferConfigured() async -> RTCPrimitive.Offer? {
                return await configuredRemoteDescription.prefix(1).collect().first?.left
        }

        func onLocalAnswerCreated() async {
                _ = await onCreateLocalAnswer.prefix(1).collect()
        }

        func completeSetLocalDescription(with result: Result<Void, any Error>) {
                setLocalDescriptionContinuation?.resume(with: result)
        }

        func completeSetRemoteDescription(with result: Result<Void, any Error>) {
                setRemoteDescriptionContinuation?.resume(with: result)
        }

	func completeCreateLocalAnswerRequest(with answer: Result<RTCPrimitive.Answer, Error>) {
		createLocalAnswerContinuation?.resume(with: answer)
	}

        func completeCreateLocalOfferRequest(with answer: Result<RTCPrimitive.Offer, Error>) {
                createLocalOfferContinuation?.resume(with: answer)
        }

	func completeAddICECandidate(with result: Result<Void, Error>) {
		addICECandidateContinuation?.resume(with: result)
	}
}
