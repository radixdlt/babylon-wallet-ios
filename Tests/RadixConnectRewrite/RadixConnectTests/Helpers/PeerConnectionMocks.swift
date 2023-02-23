import Foundation
@testable import RadixConnect

// MARK: - MockPeerConnectionFactory
final class MockPeerConnectionFactory: PeerConnectionFactory {
	let clients: [PeerConnectionClient]
	init(clients: [PeerConnectionClient]) {
		self.clients = clients
	}

	func makePeerConnectionClient(for clientID: ClientID) throws -> PeerConnectionClient {
		clients.first { $0.id == clientID }!
	}
}

// MARK: - MockPeerConnectionDelegate
final class MockPeerConnectionDelegate: PeerConnectionDelegate {
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
}

// MARK: - MockPeerConnection
final class MockPeerConnection: PeerConnection {
        func setRemoteAnswer(_ answer: RadixConnect.RTCPrimitive.Answer) async throws {

        }

        func createOffer() async throws -> RadixConnect.RTCPrimitive.Offer {
                .any
        }

        func setLocalOffer(_ offer: RadixConnect.RTCPrimitive.Offer) async throws {
                
        }

	let configuredRemoteOffer: AsyncStream<RTCPrimitive.Offer>
	let configuredLocalAnswer: AsyncStream<RTCPrimitive.Answer>
	let configuredICECandidate: AsyncStream<RTCPrimitive.ICECandidate>
	let onCreateLocalAnswer: AsyncStream<Void>

	private let configuredRemoteOfferContinuation: AsyncStream<RTCPrimitive.Offer>.Continuation
	private let configuredLocalAnswerContinuation: AsyncStream<RTCPrimitive.Answer>.Continuation
	private let configuredICECandidateContinuation: AsyncStream<RTCPrimitive.ICECandidate>.Continuation
	private let onCreateLocalAnswerContinuation: AsyncStream<Void>.Continuation
	private let stubDataChannel: Result<DataChannelClient, Error>

	private var localAnswerContinuation: CheckedContinuation<RTCPrimitive.Answer, any Error>?
	private var setRemoteOfferContinuation: CheckedContinuation<Void, any Error>?
	private var addICECandidateContinuation: CheckedContinuation<Void, any Error>?

	init(dataChannel: Result<DataChannelClient, Error> = .failure(NSError(domain: "test", code: 1))) {
		self.stubDataChannel = dataChannel
		(configuredRemoteOffer, configuredRemoteOfferContinuation) = AsyncStream<RTCPrimitive.Offer>.streamWithContinuation()
		(configuredLocalAnswer, configuredLocalAnswerContinuation) = AsyncStream<RTCPrimitive.Answer>.streamWithContinuation()
		(configuredICECandidate, configuredICECandidateContinuation) = AsyncStream<RTCPrimitive.ICECandidate>.streamWithContinuation()
		(onCreateLocalAnswer, onCreateLocalAnswerContinuation) = AsyncStream<Void>.streamWithContinuation()
	}

	func setLocalAnswer(_ answer: RTCPrimitive.Answer) async throws {
		configuredLocalAnswerContinuation.yield(answer)
	}

	func setRemoteOffer(_ offer: RTCPrimitive.Offer) async throws {
		configuredRemoteOfferContinuation.yield(offer)
		return try await withCheckedThrowingContinuation { continuation in
			setRemoteOfferContinuation = continuation
		}
	}

	func createLocalAnswer() async throws -> RTCPrimitive.Answer {
		onCreateLocalAnswerContinuation.yield(())
		return try await withCheckedThrowingContinuation { continuation in
			localAnswerContinuation = continuation
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

	func onRemoteOffer() async -> RTCPrimitive.Offer {
		await configuredRemoteOffer.first { _ in true }!
	}

	func onCreateLocalAnswer() async {
		_ = await onCreateLocalAnswer.prefix(1).collect()
	}

	func onSetLocalAnswer() async -> RTCPrimitive.Answer {
		await configuredLocalAnswer.first { _ in true }!
	}

	func completeCreateLocalAnswerRequest(with answer: Result<RTCPrimitive.Answer, Error>) {
		localAnswerContinuation?.resume(with: answer)
	}

	func completeSetRemoteOffer(with result: Result<Void, Error>) {
		setRemoteOfferContinuation?.resume(with: result)
	}

	func completeAddICECandidate(with result: Result<Void, Error>) {
		addICECandidateContinuation?.resume(with: result)
	}
}
