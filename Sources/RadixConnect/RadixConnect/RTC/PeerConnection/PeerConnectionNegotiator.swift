import Algorithms
import Foundation
import Prelude
import RadixConnectModels

// MARK: - PeerConnectionFactory
protocol PeerConnectionFactory: Sendable {
	func makePeerConnectionClient(for clientId: RemoteClientID) throws -> PeerConnectionClient
}

// MARK: - PeerConnectionNegotiator
/*
   Handles the Peer Connection negations.

   This component assumes that a single SignalingClient will be used to negotiate multiple PeerConnections.
   Thus, on each negotiation trigger(Offer or RemoteClientDidConnect), it will create a Task managing the negotiation between the Peers.
   Once the negotiation completes, the result of it will be published on `peerConnections` async sequence.
   The result of the negotiation is either a PeerConnectionClient ready for use, or the error that occurred during the negotiation.
 */
struct PeerConnectionNegotiator {
	struct FailedToCreatePeerConnectionError: Error {
		let remoteClientId: RemoteClientID
		let underlyingError: Error
	}

	typealias NegotiationResult = Result<PeerConnectionClient, FailedToCreatePeerConnectionError>
	fileprivate typealias NegotiationRole = Either<IdentifiedPrimitive<RTCPrimitive.Offer>, RemoteClientID>

	// MARK: - Negotiation

	/// The result of all started negotiations
	let negotiationResults: AnyAsyncSequence<NegotiationResult>

	private let negotiationResultsContinuation: AsyncStream<NegotiationResult>.Continuation
	private let negotiationTask: Task<Void, Error>

	// MARK: - Config
	private let signalingServerClient: SignalingClient
	private let factory: PeerConnectionFactory
	private let isOferer: Bool

	init(signalingServerClient: SignalingClient, factory: PeerConnectionFactory, isOferer: Bool = true) {
		self.signalingServerClient = signalingServerClient
		self.factory = factory
		self.isOferer = isOferer

		let (negotiationResultsStream, negotiationResultsContinuation) = AsyncStream<NegotiationResult>.streamWithContinuation()
		self.negotiationResults = negotiationResultsStream.eraseToAnyAsyncSequence().share().eraseToAnyAsyncSequence()
		self.negotiationResultsContinuation = negotiationResultsContinuation

		@Sendable func negotiate(_ role: NegotiationRole) async {
			do {
				let peerConnection = try await Self.negotiatePeerConnection(role, signalingServerClient: signalingServerClient, factory: factory)
				negotiationResultsContinuation.yield(.success(peerConnection))
			} catch {
				negotiationResultsContinuation.yield(
					.failure(
						FailedToCreatePeerConnectionError(
							remoteClientId: role.clientID,
							underlyingError: error
						)
					)
				)
			}
		}

		let negotiationTriggers: AnyAsyncSequence<NegotiationRole> = isOferer ?
			signalingServerClient.onOffer.map { NegotiationRole.answerer($0) }.eraseToAnyAsyncSequence() :
			signalingServerClient.onRemoteClientState.filter(\.remoteClientDidConnect).map { NegotiationRole.offerer($0.remoteClientId) }.eraseToAnyAsyncSequence()

		self.negotiationTask = Task {
			try await withThrowingTaskGroup(of: Void.self) { group in
				for try await trigger in negotiationTriggers {
					_ = group.addTaskUnlessCancelled {
						try Task.checkCancellation()
						guard !Task.isCancelled else { return }
						await negotiate(trigger)
					}
				}
			}
		}
	}

	func cancel() {
		negotiationResultsContinuation.finish()
		negotiationTask.cancel()
		signalingServerClient.cancel()
	}

	private static func negotiatePeerConnection(
		_ role: NegotiationRole,
		signalingServerClient: SignalingClient,
		factory: PeerConnectionFactory
	) async throws -> PeerConnectionClient {
		let clientID = role.clientID
		let log = Self.tracePeerConnectionNegotiation(clientID)

		log("Triggered")
		let peerConnectionClient = try factory.makePeerConnectionClient(for: clientID)

		let onLocalIceCandidate = peerConnectionClient
			.onGeneratedICECandidate
			.map { candidate in
				log("Sending local ICE Candidate")
				defer {
					log("Sent local ICE Candidate")
				}
				return try await signalingServerClient.sendToRemote(.init(content: .iceCandidate(candidate), id: clientID))
			}.eraseToAnyAsyncSequence()

		let onRemoteIceCandidate = signalingServerClient
			.onICECanddiate
			.filter { $0.id == clientID }
			.map {
				log("Received remote ICE Candidate")
				return try await peerConnectionClient.setRemoteICECandidate($0.content)
			}
			.eraseToAnyAsyncSequence()

		let onConnectionEstablished = peerConnectionClient
			.iceConnectionStates
			.filter {
				$0 == .connected
			}
			.prefix(1)

		_ = await peerConnectionClient.onNegotiationNeeded.prefix(1).collect()
		log("Starting negotiation")

		log("Start ICE Candidates exchange")
		let iceExchangeTask = Task {
			await withThrowingTaskGroup(of: Void.self) { group in
				onLocalIceCandidate.await(inGroup: &group)
				onRemoteIceCandidate.await(inGroup: &group)
			}
		}

		switch role {
		case let .left(offer):
			try await peerConnectionClient.setRemoteOffer(offer.content)
			log("Remote Offer was configured as local description")

			let localAnswer = try await peerConnectionClient.createAnswer()
			log("Created Answer")

			try await signalingServerClient.sendToRemote(.init(content: .answer(localAnswer), id: offer.id))
			log("Sent Answer to remote client")
		case let .right(answerrerID):
			let offer = try await peerConnectionClient.createLocalOffer()
			try await signalingServerClient.sendToRemote(.init(content: .offer(offer), id: answerrerID))
			log("Sent Offer to remote client")

			let answer = try await signalingServerClient.onAnswer.filter { $0.id == answerrerID }.prefix(1).collect().first!
			try await peerConnectionClient.setRemoteAnswer(answer.content)
			log("Received and configured remote Answer")
		}

		_ = try await onConnectionEstablished.collect()
		log("Connection established")
		iceExchangeTask.cancel()

		return peerConnectionClient
	}

	private static func tracePeerConnectionNegotiation(_ id: RemoteClientID) -> @Sendable (_ info: String) -> Void {
		{ info in
			loggerGlobal.trace("PeerConnection Negotiation for id: \(id) -> \(info)")
		}
	}
}

/// Just syntactic sugar
private extension PeerConnectionNegotiator.NegotiationRole {
	static func answerer(_ offer: IdentifiedPrimitive<RTCPrimitive.Offer>) -> Self {
		.left(offer)
	}

	static func offerer(_ remoteClientID: RemoteClientID) -> Self {
		.right(remoteClientID)
	}

	var clientID: RemoteClientID {
		self.either { offer in
			offer.id
		} ifRight: { remoteClientID in
			remoteClientID
		}
	}

	func doAsync(
		ifOfferer: (Left) async throws -> Void,
		ifAnswerer: (Right) async throws -> Void
	) async rethrows {
		try await self.doAsync(ifLeft: ifOfferer, ifRight: ifAnswerer)
	}
}
