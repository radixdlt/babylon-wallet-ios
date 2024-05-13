import WebRTC

// MARK: - PeerConnectionFactory
protocol PeerConnectionFactory: Sendable {
	func makePeerConnectionClient(for clientId: RemoteClientID) throws -> PeerConnectionClient
}

// MARK: - PeerConnectionNegotiator
/// Handles the Peer Connection negations.
/// This component assumes that a single SignalingClient will be used to negotiate multiple PeerConnections.
/// Thus, on each negotiation trigger(Offer or RemoteClientDidConnect), it will create a Task managing the negotiation between the Peers.
/// Once the negotiation completes, the result of it will be published on `negotiationResults` async sequence.
/// The result of the negotiation is either a PeerConnectionClient ready for use, or the error that occurred during the negotiation.
struct PeerConnectionNegotiator {
	struct FailedToCreatePeerConnectionError: Error {
		let remoteClientId: RemoteClientID
		let underlyingError: Error
	}

	typealias NegotiationResult = Result<PeerConnectionClient, FailedToCreatePeerConnectionError>
	fileprivate typealias NegotiationTrigger = Either<IdentifiedRTCOffer, RemoteClientID>

	// MARK: - Negotiation

	/// The result of all started negotiations
	let negotiationResults: AnyAsyncSequence<NegotiationResult>

	private let negotiationResultsContinuation: AsyncStream<NegotiationResult>.Continuation
	private let negotiationTask: Task<Void, Error>

	// MARK: - Config
	private let signalingClient: SignalingClient
	private let factory: PeerConnectionFactory

	init(
		p2pLink: P2PLink,
		isNewConnection: Bool,
		signalingClient: SignalingClient,
		factory: PeerConnectionFactory,
		isOfferer: Bool = false
	) {
		self.signalingClient = signalingClient
		self.factory = factory

		let (negotiationResultsStream, negotiationResultsContinuation) = AsyncStream<NegotiationResult>.makeStream()
		self.negotiationResults = negotiationResultsStream.eraseToAnyAsyncSequence().share().eraseToAnyAsyncSequence()
		self.negotiationResultsContinuation = negotiationResultsContinuation
		self.negotiationTask = Self.listenForNegotiationTriggers(
			p2pLink: p2pLink,
			isNewConnection: isNewConnection,
			signalingClient: signalingClient,
			factory: factory,
			isOfferer: isOfferer,
			negotiationResultsContinuation: negotiationResultsContinuation
		)
	}
}

extension PeerConnectionNegotiator {
	func cancel() {
		negotiationResultsContinuation.finish()
		negotiationTask.cancel()
		signalingClient.cancel()
	}

	private static func listenForNegotiationTriggers(
		p2pLink: P2PLink,
		isNewConnection: Bool,
		signalingClient: SignalingClient,
		factory: PeerConnectionFactory,
		isOfferer: Bool,
		negotiationResultsContinuation: AsyncStream<NegotiationResult>.Continuation
	) -> Task<Void, Error> {
		@Sendable func negotiate(_ trigger: NegotiationTrigger) async {
			do {
				let peerConnection = try await negotiatePeerConnection(
					trigger,
					p2pLink: p2pLink,
					isNewConnection: isNewConnection,
					signalingServerClient: signalingClient,
					factory: factory
				)
				negotiationResultsContinuation.yield(.success(peerConnection))
			} catch {
				negotiationResultsContinuation.yield(
					.failure(
						FailedToCreatePeerConnectionError(
							remoteClientId: trigger.clientID,
							underlyingError: error
						)
					)
				)
			}
		}

		let negotiationTriggers: AnyAsyncSequence<NegotiationTrigger> = if isOfferer {
			signalingClient.onRemoteClientState
				.filter(\.remoteClientDidConnect)
				.map { NegotiationTrigger.remoteClientDidConnect($0.remoteClientId) }
				.eraseToAnyAsyncSequence()
		} else {
			signalingClient.onOffer
				.map { NegotiationTrigger.receivedOffer($0) }
				.eraseToAnyAsyncSequence()
		}

		return Task {
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

	private static func negotiatePeerConnection(
		_ trigger: NegotiationTrigger,
		p2pLink: P2PLink,
		isNewConnection: Bool,
		signalingServerClient: SignalingClient,
		factory: PeerConnectionFactory
	) async throws -> PeerConnectionClient {
		let clientID = trigger.clientID
		let log = tracePeerConnectionNegotiation(clientID)

		log("Triggered")
		let peerConnectionClient = try factory.makePeerConnectionClient(for: clientID)

		let onLocalIceCandidate = peerConnectionClient
			.onGeneratedICECandidate
			.map { candidate in
				log("Sending local ICE Candidate")
				defer {
					log("Sent local ICE Candidate")
				}
				return try await signalingServerClient.sendToRemote(.init(.iceCandidate(candidate), id: clientID))
			}.eraseToAnyAsyncSequence()

		let onRemoteIceCandidate = signalingServerClient
			.onICECanddiate
			.filter { $0.id == clientID }
			.map {
				log("Received remote ICE Candidate")
				return try await peerConnectionClient.setRemoteICECandidate($0.value)
			}
			.eraseToAnyAsyncSequence()

		let onConnectionEstablished = peerConnectionClient
			.iceConnectionStates
			.filter {
				$0 == .connected
			}
			.prefix(1)

		let onDataChannelReady = peerConnectionClient
			.dataChannelReadyStates
			.filter {
				$0 == .connected
			}
			.prefix(1)

		_ = try await peerConnectionClient.onNegotiationNeeded.first()
		log("Starting negotiation")

		log("Start ICE Candidates exchange")
		let iceExchangeTask = Task {
			await withThrowingTaskGroup(of: Void.self) { group in
				onLocalIceCandidate.await(inGroup: &group)
				onRemoteIceCandidate.await(inGroup: &group)
			}
		}

		try await trigger.doAsync(
			receivedOffer: { offer in
				try await peerConnectionClient.setRemoteOffer(offer.value)
				log("Remote Offer was configured as local description")

				let localAnswer = try await peerConnectionClient.createAnswer()
				log("Created Answer")

				try await signalingServerClient.sendToRemote(.init(.answer(localAnswer), id: offer.id))
				log("Sent Answer to remote client")
			},
			remoteClientDidConnect: { clientID in
				let offer = try await peerConnectionClient.createLocalOffer()
				try await signalingServerClient.sendToRemote(.init(.offer(offer), id: clientID))
				log("Sent Offer to remote client")

				let answer = try await signalingServerClient.onAnswer.filter { $0.id == clientID }.first()
				try await peerConnectionClient.setRemoteAnswer(answer.value)
				log("Received and configured remote Answer")
			}
		)

		_ = try await onConnectionEstablished.collect()
		_ = try await onDataChannelReady.collect()

		if isNewConnection {
			try await sendLinkClientInteractionResponse(peerConnectionClient: peerConnectionClient, p2pLink: p2pLink) {
				log("Sent LinkClientInteractionResponse")
			}
		}

		log("Connection established")
		iceExchangeTask.cancel()

		return peerConnectionClient
	}

	private static func sendLinkClientInteractionResponse(
		peerConnectionClient: PeerConnectionClient,
		p2pLink: P2PLink,
		onSuccess: () -> Void
	) async throws {
		@Dependency(\.p2pLinksClient) var p2pLinkClient
		@Dependency(\.jsonEncoder) var jsonEncoder

		let (privateKey, isNewPrivateKey) = try await p2pLinkClient.getP2PLinkPrivateKey()
		let hashedMessageToSign = p2pLink.connectionPassword.messageHash.data
		let linkClientInteractionResponse = try P2P.ConnectorExtension.Request.LinkClientInteractionResponse(
			discriminator: .linkClient,
			publicKey: .init(bytes: privateKey.publicKey.compressedRepresentation),
			signature: .init(bytes: privateKey.signature(for: hashedMessageToSign))
		)
		try await peerConnectionClient.sendData(jsonEncoder().encode(linkClientInteractionResponse))
		onSuccess()

		if isNewPrivateKey {
			try await p2pLinkClient.storeP2PLinkPrivateKey(privateKey)
		}
	}

	private static func tracePeerConnectionNegotiation(_ id: RemoteClientID) -> @Sendable (_ info: String) -> Void {
		{ info in
			loggerGlobal.trace("PeerConnection Negotiation for id: \(id) -> \(info)")
		}
	}
}

/// Just syntactic sugar
private extension PeerConnectionNegotiator.NegotiationTrigger {
	static func receivedOffer(_ offer: IdentifiedRTCOffer) -> Self {
		.left(offer)
	}

	static func remoteClientDidConnect(_ remoteClientID: RemoteClientID) -> Self {
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
		receivedOffer: (Left) async throws -> Void,
		remoteClientDidConnect: (Right) async throws -> Void
	) async rethrows {
		try await doAsync(ifLeft: receivedOffer, ifRight: remoteClientDidConnect)
	}
}
