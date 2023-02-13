@testable import RadixConnect
import TestingPrelude

// MARK: - SignalingClientTests
@MainActor
final class SignalingServerNegotiationTests: TestCase {
        static let connectionID = try! SignalingServerConnectionID(.init(.deadbeef32Bytes))
        static let encryptionKey = try! EncryptionKey(rawValue: .init(data: .deadbeef32Bytes))
        static let ownClientId = ClientID(rawValue: UUID().uuidString)
        static let remoteClientId = ClientID(rawValue: UUID().uuidString)

        let dataChannelClient = DataChannelClient(dataChannel: DataChannelMock(), delegate: DataChannelDelegateMock())
        let answer = RTCPrimitive.Answer(sdp: "Answer_SDP")
        lazy var peerConnection = MockPeerConnection(dataChannel: .success(dataChannelClient))
        let delegate = MockPeerConnectionDelegate()
        lazy var peerConnectionFactory = MockPeerConnectionFactory(peerConnection: peerConnection, peerConnectionDelegate: delegate)
        let webSocketClient = MockWebSocketClient()

        lazy var signalingClient = SignalingClient(encryptionKey: Self.encryptionKey,
                                                   webSocketClient: webSocketClient,
                                                   connectionID: Self.connectionID,
                                                   ownClientId: Self.ownClientId)

        func test_makePeerConnection_happyFlow() async throws {
                let peerConnectionsStream = makePeerConnections(using: signalingClient, factory: peerConnectionFactory)

                let peerConnectionTask = Task {
                        try await peerConnectionsStream.prefix(1).collect()
                }

                // Receive incomming offer from remoteClientId
                let remoteOffer = IdentifiedPrimitive(content: RTCPrimitive.Offer(sdp: "SDP"), id: Self.remoteClientId)
                try await receiveOffer(remoteOffer)

                // Send answer
                let answer = IdentifiedPrimitive(content: answer, id: remoteOffer.id)
                try await sendAnswer(answer)


                // Receive ICECandidate
                let remoteICECandidate = IdentifiedPrimitive(content: RTCPrimitive.ICECandidate(sdp: "sdp", sdpMLineIndex: 2, sdpMid: "mid"), id: Self.remoteClientId)
                try await receiveICECandidate(remoteICECandidate)

                // Receive ICECandidate
                let localICECandidate = IdentifiedPrimitive(content: RTCPrimitive.ICECandidate(sdp: "sdp Local", sdpMLineIndex: 22, sdpMid: "mid_local"), id: Self.remoteClientId)
                try await sendICECandidate(localICECandidate)


                // When ICEConnection state is connected the peer connection is returned
                delegate.sendICEConnectionStateEvent(.connected)

                _ = try await peerConnectionTask.value
        }

        private func receiveOffer(_ primitive: IdentifiedPrimitive<RTCPrimitive.Offer>) async throws {
                try webSocketClient.receiveIncommingMessage(
                        makeClientMessage(.offer(primitive), requestId: .any)
                )

                // Before setting the Offer, the negotiation needed event has to occur
                delegate.sendNegotiationNeededEvent()

                let configuredOffer = await peerConnection.configuredRemoteOffer.prefix(1).collect().first!
                XCTAssertEqual(configuredOffer, primitive.content)
        }

        private func receiveICECandidate(_ primitive: IdentifiedPrimitive<RTCPrimitive.ICECandidate>) async throws {
                try webSocketClient.receiveIncommingMessage(
                        makeClientMessage(.iceCandidate(primitive), requestId: .any)
                )

                let configuredICECandidate = await peerConnection.configuredICECandidate.prefix(1).collect().first!
                XCTAssertEqual(configuredICECandidate, primitive.content)
        }

        private func sendICECandidate(_ primitive: IdentifiedPrimitive<RTCPrimitive.ICECandidate>) async throws {
                delegate.onGeneratedICECandidateContinuation.yield(primitive.content)
                try await assertDidSendMessage(.iceCandidate(primitive))

        }

        private func sendAnswer(_ primitive: IdentifiedPrimitive<RTCPrimitive.Answer>) async throws {
                peerConnection.completeCreateLocalAnswerRequest(with: primitive.content)
                let configuredAnswer = await peerConnection.configuredLocalAnswer.prefix(1).collect().first!
                XCTAssertEqual(configuredAnswer, primitive.content)
                try await assertDidSendMessage(.answer(primitive))
        }

        func assertDidSendMessage(_ primitive: RTCPrimitive) async throws {
                let sentMessageData = await webSocketClient.sentMessagesStream.prefix(1).collect().first!
                let sentMessage = try JSONDecoder().decode(ClientMessage.self, from: sentMessageData)
                XCTAssertEqual(sentMessage.method, .init(from: primitive))
                XCTAssertEqual(sentMessage.sourceClientId, Self.ownClientId)
                XCTAssertEqual(sentMessage.targetClientId, primitive.clientId)
                let sentPrimitive = try sentMessage.extractRTCPrimitive(Self.encryptionKey)
                XCTAssertEqual(sentPrimitive, primitive)
                webSocketClient.respondToRequest(message: .success(sentMessage.requestId))
        }

        func makeClientMessage(_ primitive: RTCPrimitive, requestId: RequestID) throws -> JSONValue {
                let encoded = try JSONEncoder().encode(primitive.payload)
                let encrypted = try Self.encryptionKey.encrypt(data: encoded)
                let data = JSONValue.dictionary([
                        "requestId": .string(requestId.rawValue),
                        "method": .string(ClientMessage.Method(from: primitive).rawValue),
                        "source": .string("wallet"),
                        "sourceClientId": .string(primitive.clientId.rawValue) ,
                        "targetClientId": .string(Self.ownClientId.rawValue),
                        "connectionId": .string(Self.connectionID.rawValue.data.hex()),
                        "encryptedPayload": .string(encrypted.hex),
                ])

                let remoteData = JSONValue.dictionary([
                        "info": .string("remoteData"),
                        "requestId": .string("Id"),
                        "data": data,
                ])

                return remoteData
        }
}

extension MockWebSocketClient {
        func respondToRequest(message: IncommingMessage.FromSignalingServer.ResponseForRequest) {
                receiveIncommingMessage(message.json)
        }
}

extension IncommingMessage.FromSignalingServer.ResponseForRequest {
        var json: JSONValue {
                switch self {
                case let .success(value):
                        return .dictionary([
                                "info": .string("confirmation"),
                                "requestId": .string(value.rawValue),
                        ])
                case let .failure(failure):
                        fatalError()
//                        return .dictionary([
//                                "info": .string("missingRemoteClientError"),
//                                "requestId": .string(failure.rawValue),
//                        ])
                }
        }
}

extension RequestID {
        static var any: RequestID {
                .init(rawValue: UUID().uuidString)
        }
}
final class MockPeerConnectionFactory: PeerConnectionFactory {
        let peerConnection: MockPeerConnection
        let peerConnectionDelegate: MockPeerConnectionDelegate

        init(peerConnection: MockPeerConnection, peerConnectionDelegate: MockPeerConnectionDelegate) {
                self.peerConnection = peerConnection
                self.peerConnectionDelegate = peerConnectionDelegate
        }

        func makePeerConnectionClient() throws -> PeerConnectionClient {
                try PeerConnectionClient(peerConnection: peerConnection, delegate: peerConnectionDelegate)
        }
}

final class MockPeerConnectionDelegate: PeerConnectionDelegate {
        let onNegotiationNeeded: AsyncStream<Void>
        let onIceConnectionState: AsyncStream<ICEConnectionState>
        let onSignalingState: AsyncStream<SignalingState>
        let onGeneratedICECandidate: AsyncStream<RTCPrimitive.ICECandidate>

        let onNegotiationNeededContinuation: AsyncStream<Void>.Continuation
        let onIceConnectionStateContinuation: AsyncStream<ICEConnectionState>.Continuation
        let onSignalingStateContinuation: AsyncStream<SignalingState>.Continuation
        let onGeneratedICECandidateContinuation: AsyncStream<RTCPrimitive.ICECandidate>.Continuation

        init() {
                (onNegotiationNeeded, onNegotiationNeededContinuation) = AsyncStream<Void>.streamWithContinuation()
                (onIceConnectionState, onIceConnectionStateContinuation) = AsyncStream<ICEConnectionState>.streamWithContinuation()
                (onSignalingState, onSignalingStateContinuation) = AsyncStream<SignalingState>.streamWithContinuation()
                (onGeneratedICECandidate, onGeneratedICECandidateContinuation) = AsyncStream<RTCPrimitive.ICECandidate>.streamWithContinuation()
        }

        func sendNegotiationNeededEvent() {
                onNegotiationNeededContinuation.yield(())
        }

        func sendICEConnectionStateEvent(_ state: ICEConnectionState) {
                onIceConnectionStateContinuation.yield(state)
        }
}

final class MockPeerConnection: PeerConnection {
        let dataChannel: Result<DataChannelClient, Error>

        let configuredRemoteOffer: AsyncStream<RTCPrimitive.Offer>
        let configuredLocalAnswer: AsyncStream<RTCPrimitive.Answer>
        let configuredICECandidate: AsyncStream<RTCPrimitive.ICECandidate>

        let configuredRemoteOfferContinuation: AsyncStream<RTCPrimitive.Offer>.Continuation
        let configuredLocalAnswerContinuation: AsyncStream<RTCPrimitive.Answer>.Continuation
        let configuredICECandidateContinuation: AsyncStream<RTCPrimitive.ICECandidate>.Continuation

        private var localAnswerContinuation: CheckedContinuation<RTCPrimitive.Answer, any Error>?

        init(dataChannel: Result<DataChannelClient, Error> = .failure(NSError(domain: "test", code: 1))) {
                self.dataChannel = dataChannel
                (configuredRemoteOffer, configuredRemoteOfferContinuation) = AsyncStream<RTCPrimitive.Offer>.streamWithContinuation()
                (configuredLocalAnswer, configuredLocalAnswerContinuation) = AsyncStream<RTCPrimitive.Answer>.streamWithContinuation()
                (configuredICECandidate, configuredICECandidateContinuation) = AsyncStream<RTCPrimitive.ICECandidate>.streamWithContinuation()
        }

        func setLocalAnswer(_ answer: RTCPrimitive.Answer) async throws {
                configuredLocalAnswerContinuation.yield(answer)
        }

        func setRemoteOffer(_ offer: RTCPrimitive.Offer) async throws {
                configuredRemoteOfferContinuation.yield(offer)
        }

        func createLocalAnswer() async throws -> RTCPrimitive.Answer {
                try await withCheckedThrowingContinuation({ continuation in
                        localAnswerContinuation = continuation
                })
        }

        func addRemoteICECandidate(_ candidate: RTCPrimitive.ICECandidate) async throws {
                configuredICECandidateContinuation.yield(candidate)
        }

        func createDataChannel() throws -> DataChannelClient {
                try dataChannel.get()
        }

        func completeCreateLocalAnswerRequest(with answer: RTCPrimitive.Answer) {
                localAnswerContinuation?.resume(with: .success(answer))
        }
}
