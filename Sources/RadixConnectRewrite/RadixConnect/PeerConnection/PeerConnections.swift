import Algorithms
import Foundation
import Prelude

// MARK: - PeerConnectionFactory
protocol PeerConnectionFactory: Sendable {
	func makePeerConnectionClient() throws -> PeerConnectionClient
}

// MARK: - PeerConnections
actor PeerConnections {
	private var connections: [PeerConnectionClient] = []

	private let signalingServerClient: SignalingClient
	private let factory: PeerConnectionFactory

	init(signalingServerClient: SignalingClient, factory: PeerConnectionFactory) {
		self.signalingServerClient = signalingServerClient
		self.factory = factory

		signalingServerClient
			.onRemoteClientState
			.filter(\.remoteClientDidConnect)
			.mapSkippingError { _ in
				try factory.makePeerConnectionClient()
			} logError: { err in
				loggerGlobal.error("Failed to create PeerConnectionClient \(err)")
			}
			.mapSkippingError {
				// negotiate
				try await self.negotiation(signalingServerClient, $0)
			} logError: { error in
				loggerGlobal.error("Failed to negotiate PeerConnection \(error)")
			}
			.handleEvents(onElement: {
				// store the created PeerConnection
				await self.savePeerConnection($0)
			})
	}

	private func savePeerConnection(_ connection: PeerConnectionClient) {
		self.connections.append(connection)
	}

	func negotiation(_ signaling: SignalingClient, _ peerConnection: PeerConnectionClient) async throws -> PeerConnectionClient {
		let onLocalOffer = peerConnection.onNegotiationNeeded.map {
			try await peerConnection.createOffer()
		}.map {
			try await signaling.sendToRemote(rtcPrimitive: .offer($0))
		}.eraseToAnyAsyncSequence()

		let onRemoteAnswer = signaling.onAnswer.map {
			try await peerConnection.onRemoteAnswer($0)
		}.eraseToAnyAsyncSequence()

		let onLocalICECandidate = peerConnection.onGeneratedICECandidate.map {
			try await signaling.sendToRemote(rtcPrimitive: .addICE($0))
		}.eraseToAnyAsyncSequence()

		let onRemoteICECandidate = signaling.onICECanddiate.map {
			try await peerConnection.onRemoteICECandidate($0)
		}.eraseToAnyAsyncSequence()

		let onConnectionCompleted = peerConnection.onIceConnectionState.filter { $0 == .connected }

		// When Connection established

		await withThrowingTaskGroup(of: Void.self) { group in
			// Local to Remote communication
			onLocalOffer.await(inGroup: &group) // should happen only once
			onLocalICECandidate.await(inGroup: &group) // multiple values

			// Remote to local communication
			onRemoteAnswer.await(inGroup: &group) // only once
			onRemoteICECandidate.await(inGroup: &group) // multiple values

			// Wait until the connection is established
			await peerConnection.onIceConnectionState.filter { $0 == .connected }.prefix(1).collect()
		}

		return peerConnection
	}
}

extension AsyncSequence where Element == Void {
	func await(inGroup group: inout ThrowingTaskGroup<Void, Error>) where Self: Sendable {
		_ = group.addTaskUnlessCancelled {
			try Task.checkCancellation()
			for try await _ in self {
				guard !Task.isCancelled else { return }
			}
		}
	}
}

// MARK: - Factory
protocol Factory {
	func makePeerConnection() -> PeerConnection
}
