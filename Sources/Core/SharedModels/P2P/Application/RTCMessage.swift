import RadixConnectModels

public extension P2P {
	typealias RTCIncomingMessageResult = RTCIncomingMessage<Result<P2P.FromDapp.WalletInteraction, Error>>
	typealias RTCIncomingWalletInteraction = RTCIncomingMessage<P2P.FromDapp.WalletInteraction>

	struct RTCIncomingMessage<PeerConnectionContent: Sendable>: Sendable {
		public let connectionId: ConnectionPassword
		public let peerMessage: PeerConnectionMessage

		public struct PeerConnectionMessage: Sendable {
			public let peerConnectionId: PeerConnectionID
			public let content: PeerConnectionContent

			public init(peerConnectionId: PeerConnectionID, content: PeerConnectionContent) {
				self.peerConnectionId = peerConnectionId
				self.content = content
			}
		}

		public init(connectionId: ConnectionPassword, content: PeerConnectionMessage) {
			self.connectionId = connectionId
			self.peerMessage = content
		}
	}

	struct RTCOutgoingMessage: Sendable, Hashable {
		public let connectionId: ConnectionPassword
		public let peerMessage: PeerConnectionMessage

		public struct PeerConnectionMessage: Sendable, Hashable {
			public let peerConnectionId: PeerConnectionID
			public let content: P2P.ToDapp.WalletInteractionResponse

			public init(peerConnectionId: PeerConnectionID, content: P2P.ToDapp.WalletInteractionResponse) {
				self.peerConnectionId = peerConnectionId
				self.content = content
			}
		}

		public init(connectionId: ConnectionPassword, content: PeerConnectionMessage) {
			self.connectionId = connectionId
			self.peerMessage = content
		}
	}
}

public extension P2P.RTCIncomingMessage where PeerConnectionContent == Result<P2P.FromDapp.WalletInteraction, Error> {
	func unwrapResult() throws -> P2P.RTCIncomingWalletInteraction {
		try .init(
			connectionId: connectionId,
			content: .init(
				peerConnectionId: peerMessage.peerConnectionId,
				content: peerMessage.content.get()
			)
		)
	}
}

public extension P2P.RTCIncomingMessage {
	/// Transforms to an OutgoingMessage by preserving the RTCClient and PeerConnection IDs
	func toOutgoingMessage(_ response: P2P.ToDapp.WalletInteractionResponse) -> P2P.RTCOutgoingMessage {
		.init(
			connectionId: connectionId,
			content: .init(
				peerConnectionId: peerMessage.peerConnectionId,
				content: response
			)
		)
	}
}

// MARK: - P2P.RTCIncomingMessage.PeerConnectionMessage + Hashable, Equatable
extension P2P.RTCIncomingMessage.PeerConnectionMessage: Hashable, Equatable where PeerConnectionContent: Hashable & Equatable {}

// MARK: - P2P.RTCIncomingMessage + Hashable, Equatable
extension P2P.RTCIncomingMessage: Hashable, Equatable where PeerConnectionContent: Hashable & Equatable {}
