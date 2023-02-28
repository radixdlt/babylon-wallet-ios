import Algorithms
import Foundation
import Prelude

// MARK: - PeerConnectionFactory
protocol PeerConnectionFactory: Sendable {
	func makePeerConnectionClient(for clientId: ClientID) throws -> PeerConnectionClient
}

// MARK: - OfferingPeerConnectionBuilder
struct OfferingPeerConnectionBuilder: Sendable {
	static func negotiatePeerConnection(signalingServerClient: SignalingClient,
	                                    factory: PeerConnectionFactory = WebRTCFactory()) async throws -> PeerConnectionClient
	{
		let clientDidConnect = try await signalingServerClient
			.onRemoteClientState
			.filter(\.remoteClientDidConnect)
			.prefix(1).collect().first!
		let clientId = clientDidConnect.remoteClientId

		print("Bigga test WebPage - client did connect to signaling server \(clientId)")
		let peerConnectionClient = try factory.makePeerConnectionClient(for: clientId)

		let onLocalIceCandidate = peerConnectionClient
			.onGeneratedICECandidate
			.map { candidate in
				try await signalingServerClient.sendToRemote(.init(content: .iceCandidate(candidate), id: clientId))
			}.eraseToAnyAsyncSequence()

		let onRemoteIceCandidate = signalingServerClient
			.onICECanddiate
			.filter { $0.id == clientId }
			.map {
				try await peerConnectionClient.onRemoteICECandidate($0.content)
			}
			.eraseToAnyAsyncSequence()

		let onConnectionEstablished = peerConnectionClient
			.onIceConnectionState
			.filter {
				$0 == .connected
			}
			.prefix(1)

		let iceExchangeTask = Task {
			await withThrowingTaskGroup(of: Void.self) { group in
				onLocalIceCandidate.await(inGroup: &group)
				onRemoteIceCandidate.await(inGroup: &group)
			}
		}

		_ = await peerConnectionClient.onNegotiationNeeded.prefix(1).collect()
		print("Bigga test WebPage - starting negotiation for \(clientId)")
		let offer = try await peerConnectionClient.createOffer()
		try await signalingServerClient.sendToRemote(.init(content: .offer(offer), id: clientId))

		print("Bigga test WebPage - sent offer to \(clientId)")

		let answer = try await signalingServerClient.onAnswer.filter { $0.id == clientId }.prefix(1).collect().first!
		try await peerConnectionClient.onRemoteAnswer(answer.content)

		print("Bigga test WebPage - received answer from \(clientId)")

		_ = try await onConnectionEstablished.collect()

		print("Bigga test WebPage - connection established with \(clientId)")
		iceExchangeTask.cancel()
		return peerConnectionClient
	}
}

// MARK: - PeerConnectionBuilder
struct PeerConnectionBuilder {
	let peerConnections: AsyncStream<Result<PeerConnectionClient, FailedToCreatePeerConnectionError>>

	private let signalingServerClient: SignalingClient
	private let factory: PeerConnectionFactory
	private let peerConnectionsContinuation: AsyncStream<Result<PeerConnectionClient, FailedToCreatePeerConnectionError>>.Continuation
	private let negotiationTask: Task<Void, Error>

	init(signalingServerClient: SignalingClient, factory: PeerConnectionFactory) {
		self.signalingServerClient = signalingServerClient
		self.factory = factory

		let (peerConnections, peerConnectionsContinuation) = AsyncStream<Result<PeerConnectionClient, FailedToCreatePeerConnectionError>>.streamWithContinuation()
		self.peerConnections = peerConnections
		self.peerConnectionsContinuation = peerConnectionsContinuation

		@Sendable func negotiate(_ offer: IdentifiedPrimitive<RTCPrimitive.Offer>) async {
			do {
				let peerConnection = try await Self.negotiatePeerConnection(offer, signalingServerClient: signalingServerClient, factory: factory)
				peerConnectionsContinuation.yield(.success(peerConnection))
			} catch {
				peerConnectionsContinuation.yield(
					.failure(
						FailedToCreatePeerConnectionError(
							remoteClientId: offer.id,
							underlyingError: error
						)
					)
				)
			}
		}

		self.negotiationTask = Task {
			try await withThrowingTaskGroup(of: Void.self) { group in
				for try await offer in signalingServerClient.onOffer {
					_ = group.addTaskUnlessCancelled {
						try Task.checkCancellation()
						guard !Task.isCancelled else { return }
						await negotiate(offer)
					}
				}
			}
		}
	}

	func cancel() {
		peerConnectionsContinuation.finish()
		negotiationTask.cancel()
		signalingServerClient.cancel()
	}

	static func negotiatePeerConnection(_ offer: IdentifiedPrimitive<RTCPrimitive.Offer>,
	                                    signalingServerClient: SignalingClient,
	                                    factory: PeerConnectionFactory) async throws -> PeerConnectionClient
	{
                loggerGlobal.trace("Received Offer with id: \(offer.id)")
		let peerConnectionClient = try factory.makePeerConnectionClient(for: offer.id)

		let onLocalIceCandidate = peerConnectionClient
			.onGeneratedICECandidate
			.map { candidate in
                                loggerGlobal.trace("Connection id: \(offer.id) -> Sending local ICE Candidate")
				return try await signalingServerClient.sendToRemote(.init(content: .iceCandidate(candidate), id: offer.id))
			}.eraseToAnyAsyncSequence()

		let onRemoteIceCandidate = signalingServerClient
			.onICECanddiate
			.filter { $0.id == offer.id }
			.map {
                                loggerGlobal.trace("Connection id: \(offer.id) -> Received remote ICE Candidate")
				return try await peerConnectionClient.onRemoteICECandidate($0.content)
			}
			.eraseToAnyAsyncSequence()

		let onConnectionEstablished = peerConnectionClient
			.onIceConnectionState
			.filter {
				$0 == .connected
			}
			.prefix(1)

		_ = await peerConnectionClient.onNegotiationNeeded.prefix(1).collect()
                loggerGlobal.trace("Connection id: \(offer.id) -> Starting negotiation")
		try await peerConnectionClient.onRemoteOffer(offer.content)
                loggerGlobal.trace("Connection id: \(offer.id) -> Remote Offer was configured as local description")
		let localAnswer = try await peerConnectionClient.createAnswer()
                loggerGlobal.trace("Connection id: \(offer.id) -> Created Answer")
		try await signalingServerClient.sendToRemote(.init(content: .answer(localAnswer), id: offer.id))
                loggerGlobal.trace("Connection id: \(offer.id) -> Sent Answer to remote client")

                loggerGlobal.trace("Connection id: \(offer.id) -> Start ICE Candidates exchange")
		let iceExchangeTask = Task {
			await withThrowingTaskGroup(of: Void.self) { group in
				onLocalIceCandidate.await(inGroup: &group)
				onRemoteIceCandidate.await(inGroup: &group)
			}
		}

		_ = try await onConnectionEstablished.collect()
                loggerGlobal.trace("Connection id: \(offer.id) -> Connection established")
		iceExchangeTask.cancel()
		return peerConnectionClient
	}
}

// MARK: - FailedToCreatePeerConnectionError
struct FailedToCreatePeerConnectionError: Error {
	let remoteClientId: ClientID
	let underlyingError: Error
}
