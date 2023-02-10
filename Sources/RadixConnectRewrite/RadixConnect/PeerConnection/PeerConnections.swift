import Algorithms
import Foundation
import Prelude

// MARK: - PeerConnectionFactory
protocol PeerConnectionFactory: Sendable {
	func makePeerConnectionClient() throws -> PeerConnectionClient
}


func makePeerConnections(using signalingServerClient: SignalingClient, factory: PeerConnectionFactory) -> AnyAsyncSequence<Result<PeerConnectionClient, Error>> {
        @Sendable func negotiatePeerConnection(_ offer: IdentifiedPrimitive<RTCPrimitive.Offer>) async throws -> PeerConnectionClient {
                let peerConnectionClient = try factory.makePeerConnectionClient()

                let onLocalIceCandidate = peerConnectionClient.onGeneratedICECandidate.map {
                        IdentifiedPrimitive(content: $0, id: offer.id)
                }.map {
                        try await signalingServerClient.sendToRemote(rtcPrimitive: .iceCandidate($0))
                }.eraseToAnyAsyncSequence()

                let onRemoteIceCandidate = signalingServerClient.onICECanddiate.map {
                       try await peerConnectionClient.onRemoteICECandidate($0.content)
                }.eraseToAnyAsyncSequence()

                let localAnswer = try await peerConnectionClient.createAnswer()
                try await signalingServerClient.sendToRemote(rtcPrimitive: .answer(.init(content: localAnswer, id: offer.id)))

                await withThrowingTaskGroup(of: Void.self) { group in
                        onLocalIceCandidate.await(inGroup: &group)
                        onRemoteIceCandidate.await(inGroup: &group)

                        group.addTask {
                                // Determin the best way to know when the data channel did open
                                await peerConnectionClient.onIceConnectionState.filter { $0 == .connected }.prefix(1).collect()
                        }
                }

                return peerConnectionClient
        }

        return signalingServerClient
                .onOffer
                .map {
                       try await negotiatePeerConnection($0)
                }
                .mapToResult()
                .eraseToAnyAsyncSequence()

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
