import Foundation
import AsyncExtensions

protocol WebSocketClient: Sendable {
        var stateStream: AsyncStream<URLSessionWebSocketTask.State> { get }
        var incomingMessageStream: AsyncThrowingStream<Data, Error> { get }

        func send(message: Data) async throws
        func close(with closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?)
}

// MARK: - AnyAsyncIterator + Sendable
extension AnyAsyncIterator: @unchecked Sendable where Self.Element: Sendable {}

// MARK: - AnyAsyncSequence + Sendable
extension AnyAsyncSequence: @unchecked Sendable where Self.AsyncIterator: Sendable {}

struct SignalingClient {
        private let incommingMessages: AnyAsyncSequence<IncommingMessage>
        private let incommingSignalingServerMessagges: AnyAsyncSequence<IncommingMessage.FromSignalingServer>
        let incommingRemoteClientMessagges: AnyAsyncSequence<RTCPrimitive>

        private let encryptionKey: EncryptionKey
        private let webSocketClient: WebSocketClient
        private let jsonDecoder: JSONDecoder
        private let jsonEncoder: JSONEncoder
        private let connectionID: SignalingServerConnectionID

        let idBuilder: @Sendable () -> RequestID

        let onICECanddiate: AnyAsyncSequence<RTCPrimitive.ICECandidate>
        let onOffer: AnyAsyncSequence<RTCPrimitive.Offer>
        let onAnswer: AnyAsyncSequence<RTCPrimitive.Answer>
        let onRemoteClientState: AnyAsyncSequence<IncommingMessage.FromSignalingServer.Notification>

        init(encryptionKey: EncryptionKey,
             webSocketClient: WebSocketClient,
             connectionID: SignalingServerConnectionID,
             idBuilder: @Sendable @escaping () -> RequestID = { .init(UUID().uuidString) },
             jsonDecoder: JSONDecoder = .init(),
             jsonEncoder: JSONEncoder = .init()
        ) {

                self.encryptionKey = encryptionKey
                self.webSocketClient = webSocketClient
                self.connectionID = connectionID
                self.idBuilder = idBuilder
                self.jsonEncoder = jsonEncoder
                self.jsonDecoder = jsonDecoder

                self.incommingMessages = webSocketClient
                        .incomingMessageStream
                        .eraseToAnyAsyncSequence()
                        .map {
                                do {
                                        let msg = try jsonDecoder.decode(IncommingMessage.self, from: $0)
                                        return msg
                                } catch {
                                        throw error
                                }

                        }
                        .compactMap {
                                let x = $0
                                return x
                        }
                        .share()
                        .eraseToAnyAsyncSequence()

                self.incommingRemoteClientMessagges = self.incommingMessages
                        .compactMap {
                                $0.fromRemoteClient
                        }
                        .map { [encryption = encryptionKey] message in
                                try message.extractRTCPrimitive(encryption, decoder: jsonDecoder)
                        }
                        .share()
                        .eraseToAnyAsyncSequence()
                
                self.incommingSignalingServerMessagges = self.incommingMessages
                        .compactMap {
                                $0.fromSignalingServer
                        }
                        .share()
                        .eraseToAnyAsyncSequence()

                self.onOffer = self.incommingRemoteClientMessagges
                        .compactMap(\.offer)
                        .eraseToAnyAsyncSequence()

                self.onAnswer = self.incommingRemoteClientMessagges
                        .compactMap(\.answer)
                        .share()
                        .eraseToAnyAsyncSequence()

                self.onICECanddiate = self.incommingRemoteClientMessagges
                        .compactMap(\.addICE)
                        .eraseToAnyAsyncSequence()

                self.onRemoteClientState = self.incommingSignalingServerMessagges
                        .compactMap(\.notification)
                        .eraseToAnyAsyncSequence()
        }

        public func sendToRemote(rtcPrimitive: RTCPrimitive) async throws {
                let id = idBuilder()
                let encodedPrimitive = try jsonEncoder.encode(rtcPrimitive)
                let encryptedPrimitive = try encryptionKey.encrypt(data: encodedPrimitive)
                let encryptedPayload = EncryptedPayload.init(.init(data: encryptedPrimitive))
                let hex = encryptedPrimitive.hex
                let message = ClientMessage(requestId: id,
                                            method: .init(from: rtcPrimitive),
                                            source: .wallet,
                                            connectionId: connectionID,
                                            encryptedPayload: encryptedPayload)

                let encodedMessage = try jsonEncoder.encode(message)

                try await webSocketClient.send(message: encodedMessage)
                try await waitForRequestAck(id)
        }

        private func waitForRequestAck(_ requestId: RequestID) async throws {
                try await self.incommingSignalingServerMessagges
                        .compactMap(\.responseForRequest)
                        .compactMap { incoming in
                                return try incoming.resultOfRequest(id: requestId)?.get()
                        }
                        .first { true }
        }
}
