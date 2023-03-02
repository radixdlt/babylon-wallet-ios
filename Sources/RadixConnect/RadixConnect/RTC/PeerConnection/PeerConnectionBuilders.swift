import Algorithms
import Foundation
import Prelude
import RadixConnectModels

// MARK: - PeerConnectionFactory
protocol PeerConnectionFactory: Sendable {
	func makePeerConnectionClient(for clientId: RemoteClientID) throws -> PeerConnectionClient
}

/// Handles the Peer Connection negations
struct PeerConnectionBuilder {
        struct FailedToCreatePeerConnectionError: Error {
                let remoteClientId: RemoteClientID
                let underlyingError: Error
        }

        private enum NegotiationRole {
                case answerer(IdentifiedPrimitive<RTCPrimitive.Offer>)
                case offerer(RemoteClientID)

                var clientID: RemoteClientID {
                        switch self {
                        case let .offerer(clientID):
                                return clientID
                        case let .answerer(offer):
                                return offer.id
                        }
                }
        }

        // MARK: - Negotiation

        /// The result of all started negotiations
        let peerConnections: AnyAsyncSequence<Result<PeerConnectionClient, FailedToCreatePeerConnectionError>>
        private let peerConnectionsContinuation: AsyncStream<Result<PeerConnectionClient, FailedToCreatePeerConnectionError>>.Continuation
        private let negotiationTask: Task<Void, Error>

        // MARK: - Config
        private let signalingServerClient: SignalingClient
        private let factory: PeerConnectionFactory
        private let isOferer: Bool

        init(signalingServerClient: SignalingClient, factory: PeerConnectionFactory, isOferer: Bool = true) {
                self.signalingServerClient = signalingServerClient
                self.factory = factory
                self.isOferer = isOferer

                let (peerConnectionsStream, peerConnectionsContinuation) = AsyncStream<Result<PeerConnectionClient, FailedToCreatePeerConnectionError>>.streamWithContinuation()
                self.peerConnections = peerConnectionsStream.eraseToAnyAsyncSequence().share().eraseToAnyAsyncSequence()
                self.peerConnectionsContinuation = peerConnectionsContinuation

                @Sendable func negotiate(_ role: NegotiationRole) async {
                        do {
                                let peerConnection = try await Self.negotiatePeerConnection(role, signalingServerClient: signalingServerClient, factory: factory)
                                peerConnectionsContinuation.yield(.success(peerConnection))
                        } catch {
                                peerConnectionsContinuation.yield(
                                        .failure(
                                                FailedToCreatePeerConnectionError(
                                                        remoteClientId: role.clientID,
                                                        underlyingError: error
                                                )
                                        )
                                )
                        }
                }

                let negotiationTrigger: AnyAsyncSequence<NegotiationRole> = isOferer ?
                signalingServerClient.onOffer.map { NegotiationRole.answerer($0) }.eraseToAnyAsyncSequence() :
                signalingServerClient.onRemoteClientState.filter(\.remoteClientDidConnect).map { NegotiationRole.offerer($0.remoteClientId) }.eraseToAnyAsyncSequence()

                self.negotiationTask = Task {
                        try await withThrowingTaskGroup(of: Void.self) { group in
                                        for try await trigger in negotiationTrigger{
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
                peerConnectionsContinuation.finish()
                negotiationTask.cancel()
                signalingServerClient.cancel()
        }

        private static func negotiatePeerConnection(_ role: NegotiationRole,
                                            signalingServerClient: SignalingClient,
                                            factory: PeerConnectionFactory) async throws -> PeerConnectionClient
        {
                let clientID = role.clientID
                loggerGlobal.trace("Received Offer with id: \(clientID)")
                let peerConnectionClient = try factory.makePeerConnectionClient(for: clientID)

                let onLocalIceCandidate = peerConnectionClient
                        .onGeneratedICECandidate
                        .map { candidate in
                                loggerGlobal.trace("Connection id: \(clientID) -> Sending local ICE Candidate")
                                return try await signalingServerClient.sendToRemote(.init(content: .iceCandidate(candidate), id: clientID))
                        }.eraseToAnyAsyncSequence()

                let onRemoteIceCandidate = signalingServerClient
                        .onICECanddiate
                        .filter { $0.id == clientID }
                        .map {
                                loggerGlobal.trace("Connection id: \(clientID) -> Received remote ICE Candidate")
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
                loggerGlobal.trace("Connection id: \(clientID) -> Starting negotiation")

                loggerGlobal.trace("Connection id: \(clientID) -> Start ICE Candidates exchange")
                let iceExchangeTask = Task {
                        await withThrowingTaskGroup(of: Void.self) { group in
                                onLocalIceCandidate.await(inGroup: &group)
                                onRemoteIceCandidate.await(inGroup: &group)
                        }
                }

                switch role {
                case let .answerer(offer):
                        try await peerConnectionClient.setRemoteOffer(offer.content)
                        loggerGlobal.trace("Connection id: \(clientID) -> Remote Offer was configured as local description")

                        let localAnswer = try await peerConnectionClient.createAnswer()
                        loggerGlobal.trace("Connection id: \(clientID) -> Created Answer")

                        try await signalingServerClient.sendToRemote(.init(content: .answer(localAnswer), id: offer.id))
                        loggerGlobal.trace("Connection id: \(clientID) -> Sent Answer to remote client")
                case let .offerer(clientID):
                        let offer = try await peerConnectionClient.createLocalOffer()
                        try await signalingServerClient.sendToRemote(.init(content: .offer(offer), id: clientID))
                        loggerGlobal.trace("Connection id: \(clientID) -> Sent Offer to remote client")

                        let answer = try await signalingServerClient.onAnswer.filter { $0.id == clientID }.prefix(1).collect().first!
                        try await peerConnectionClient.setRemoteAnswer(answer.content)
                        loggerGlobal.trace("Connection id: \(clientID) -> Received and configured remote Answer")
                }

                _ = try await onConnectionEstablished.collect()
                loggerGlobal.trace("Connection id: \(clientID) -> Connection established")
                iceExchangeTask.cancel()

                return peerConnectionClient
        }
}
