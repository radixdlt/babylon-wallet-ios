import RadixConnectModels

public extension P2P {
        typealias RTCIncommingMessageResult = RTCIncommingMessage<Result<P2P.FromDapp.WalletInteraction, Error>>
        typealias RTCIncommingWalletInteraction = RTCIncommingMessage<P2P.FromDapp.WalletInteraction>

        // MARK: - RTCIncommingMessage
        struct RTCIncommingMessage<PeerConnectionContent: Sendable>: Sendable {
                public let connectionId: ConnectionPassword
                public let content: PeerConnectionMessage

                public struct PeerConnectionMessage: Sendable {
                        public let peerConnectionId: PeerConnectionId
                        public let content: PeerConnectionContent

                        public init(peerConnectionId: PeerConnectionId, content: PeerConnectionContent) {
                                self.peerConnectionId = peerConnectionId
                                self.content = content
                        }
                }

                public init(connectionId: ConnectionPassword, content: PeerConnectionMessage) {
                        self.connectionId = connectionId
                        self.content = content
                }
        }

        // MARK: - RTCOutgoingMessage
        struct RTCOutgoingMessage: Sendable, Hashable {
                public let connectionId: ConnectionPassword
                public let content: PeerConnectionMessage

                public struct PeerConnectionMessage: Sendable, Hashable {
                        public let peerConnectionId: PeerConnectionId
                        public let content: P2P.ToDapp.WalletInteractionResponse

                        public init(peerConnectionId: PeerConnectionId, content: P2P.ToDapp.WalletInteractionResponse) {
                                self.peerConnectionId = peerConnectionId
                                self.content = content
                        }
                }

                public init(connectionId: ConnectionPassword, content: PeerConnectionMessage) {
                        self.connectionId = connectionId
                        self.content = content
                }
        }
}

public extension P2P.RTCIncommingMessage where PeerConnectionContent == Result<P2P.FromDapp.WalletInteraction, Error> {
        func unwrapResult() throws -> P2P.RTCIncommingWalletInteraction {
                try .init(connectionId: connectionId,
                          content: .init(peerConnectionId: content.peerConnectionId, content: content.content.get()))
        }
}

public extension P2P.RTCIncommingMessage {
        func toOutgoingMessage(_ response: P2P.ToDapp.WalletInteractionResponse) -> P2P.RTCOutgoingMessage {
                .init(connectionId: connectionId,
                      content: .init(peerConnectionId: content.peerConnectionId,
                                     content: response))
        }
}

// MARK: - RTCIncommingMessage.PeerConnectionMessage + Hashable, Equatable
extension P2P.RTCIncommingMessage.PeerConnectionMessage: Hashable, Equatable where PeerConnectionContent: Hashable & Equatable {}

// MARK: - RTCIncommingMessage + Hashable, Equatable
extension P2P.RTCIncommingMessage: Hashable, Equatable where PeerConnectionContent: Hashable & Equatable {}
