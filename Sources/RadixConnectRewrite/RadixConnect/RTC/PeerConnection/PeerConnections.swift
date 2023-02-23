import Algorithms
import Foundation
import Prelude

// MARK: - PeerConnectionFactory
protocol PeerConnectionFactory: Sendable {
	func makePeerConnectionClient(for clientId: ClientID) throws -> PeerConnectionClient
}

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
                                return try await signalingServerClient.sendToRemote(.init(content: .iceCandidate(candidate), id: clientId))
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

                _ = await onConnectionEstablished.collect()

                print("Bigga test WebPage - connection established with \(clientId)")
                iceExchangeTask.cancel()
                return peerConnectionClient
        }
}

// MARK: - PeerConnectionBuilder
final class PeerConnectionBuilder: Sendable {
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

	deinit {
		negotiationTask.cancel()
	}

	static func negotiatePeerConnection(_ offer: IdentifiedPrimitive<RTCPrimitive.Offer>,
	                                    signalingServerClient: SignalingClient,
	                                    factory: PeerConnectionFactory) async throws -> PeerConnectionClient
	{
                print("Bigga test Wallet - received offer from \(offer.id)")
		let peerConnectionClient = try factory.makePeerConnectionClient(for: offer.id)

		let onLocalIceCandidate = peerConnectionClient
			.onGeneratedICECandidate
			.map { candidate in
                                return try await signalingServerClient.sendToRemote(.init(content: .iceCandidate(candidate), id: offer.id))
			}.eraseToAnyAsyncSequence()

		let onRemoteIceCandidate = signalingServerClient
			.onICECanddiate
			.filter { $0.id == offer.id }
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

		_ = await peerConnectionClient.onNegotiationNeeded.prefix(1).collect()
                print("Bigga test Wallet - starting negotiation with \(offer.id)")
		try await peerConnectionClient.onRemoteOffer(offer.content)
		let localAnswer = try await peerConnectionClient.createAnswer()
                try await signalingServerClient.sendToRemote(.init(content: .answer(localAnswer), id: offer.id))
                print("Bigga test Wallet - sent answer \(offer.id)")

		let iceExchangeTask = Task {
			await withThrowingTaskGroup(of: Void.self) { group in
				onLocalIceCandidate.await(inGroup: &group)
				onRemoteIceCandidate.await(inGroup: &group)
			}
		}

		_ = await onConnectionEstablished.collect()

                print("Bigga test Wallet - Etablished connection with \(offer.id)")
		iceExchangeTask.cancel()
		return peerConnectionClient
	}
}

// MARK: - FailedToCreatePeerConnectionError
struct FailedToCreatePeerConnectionError: Error {
	let remoteClientId: ClientID
	let underlyingError: Error
}
