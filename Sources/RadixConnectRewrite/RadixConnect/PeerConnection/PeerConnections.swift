import Algorithms
import Foundation
import Prelude

// MARK: - PeerConnectionFactory
protocol PeerConnectionFactory: Sendable {
	func makePeerConnectionClient(for clienclientIDtId: ClientID) throws -> PeerConnectionClient
}

// MARK: - PeerConnectionBuilder
final class PeerConnectionBuilder {
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
		let peerConnectionClient = try factory.makePeerConnectionClient(for: offer.id)

		let onLocalIceCandidate = peerConnectionClient
			.onGeneratedICECandidate
			.map { candidate in
				let primitive = IdentifiedPrimitive(content: candidate, id: offer.id)
				return try await signalingServerClient.sendToRemote(rtcPrimitive: .iceCandidate(primitive))
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
		try await peerConnectionClient.onRemoteOffer(offer.content)
		let localAnswer = try await peerConnectionClient.createAnswer()
		try await signalingServerClient.sendToRemote(rtcPrimitive: .answer(.init(content: localAnswer, id: offer.id)))

		let iceExchangeTask = Task {
			await withThrowingTaskGroup(of: Void.self) { group in
				onLocalIceCandidate.await(inGroup: &group)
				onRemoteIceCandidate.await(inGroup: &group)
			}
		}

		_ = await onConnectionEstablished.collect()
		iceExchangeTask.cancel()
		return peerConnectionClient
	}
}

// MARK: - FailedToCreatePeerConnectionError
struct FailedToCreatePeerConnectionError: Error {
	let remoteClientId: ClientID
	let underlyingError: Error
}
