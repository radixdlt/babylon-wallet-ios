import RadixConnectModels

extension P2P {
	public typealias RTCIncomingMessageResult = RTCIncomingMessage<Result<P2P.FromDapp.WalletInteraction, Error>>
	public typealias RTCIncomingWalletInteraction = RTCIncomingMessage<P2P.FromDapp.WalletInteraction>

	public struct RTCIncomingMessage<PeerConnectionContent: Sendable>: Sendable {
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

	public struct RTCOutgoingMessage: Sendable, Hashable {
		public let connectionId: ConnectionPassword
		public let peerMessage: PeerConnectionMessage

		public struct PeerConnectionMessage: Sendable, Hashable {
			public let peerConnectionId: PeerConnectionID
			public let content: Content

			public enum Content: Sendable, Hashable, Encodable {
				/// All Dapp interactions
				case dapp(P2P.ToDapp.WalletInteractionResponse)

				/// e.g. for Ledger Nano interaction
				case connectorExtension

				public var dapp: P2P.ToDapp.WalletInteractionResponse? {
					guard case let .dapp(toDapp) = self else { return nil }
					return toDapp
				}
			}

			public init(
				peerConnectionId: PeerConnectionID,
				content: Content
			) {
				self.peerConnectionId = peerConnectionId
				self.content = content
			}

			public static func toDapp(
				response: P2P.ToDapp.WalletInteractionResponse,
				peerConnectionId: PeerConnectionID
			) -> Self {
				.init(
					peerConnectionId: peerConnectionId,
					content: .dapp(response)
				)
			}
		}

		public init(
			connectionId: ConnectionPassword,
			content: PeerConnectionMessage
		) {
			self.connectionId = connectionId
			self.peerMessage = content
		}

		public static func toDapp(
			response: P2P.ToDapp.WalletInteractionResponse,
			peerConnectionId: PeerConnectionID, // is this calculated from ConnectionPassword
			connectionId: ConnectionPassword
		) -> Self {
			.init(
				connectionId: connectionId,
				content: .toDapp(response: response, peerConnectionId: peerConnectionId)
			)
		}
	}
}

extension P2P.RTCOutgoingMessage.PeerConnectionMessage.Content {
	public func encode(to encoder: Encoder) throws {
		switch self {
		case let .dapp(toDapp):
			try toDapp.encode(to: encoder)
		case .connectorExtension:
			fatalError("impl me")
		}
	}
}

extension P2P.RTCIncomingMessage where PeerConnectionContent == Result<P2P.FromDapp.WalletInteraction, Error> {
	public func unwrapResult() throws -> P2P.RTCIncomingWalletInteraction {
		try .init(
			connectionId: connectionId,
			content: .init(
				peerConnectionId: peerMessage.peerConnectionId,
				content: peerMessage.content.get()
			)
		)
	}
}

extension P2P.RTCIncomingMessage {
	/// Transforms an incoming message FromDapp to an OutgoingMessage to Dapp
	/// by preserving the RTCClient and PeerConnection IDs
	public func toDapp(response: P2P.ToDapp.WalletInteractionResponse) -> P2P.RTCOutgoingMessage {
		.init(
			connectionId: connectionId,
			content: .toDapp(
				response: response,
				peerConnectionId: peerMessage.peerConnectionId
			)
		)
	}
}

// MARK: - P2P.RTCIncomingMessage.PeerConnectionMessage + Hashable, Equatable
extension P2P.RTCIncomingMessage.PeerConnectionMessage: Hashable, Equatable where PeerConnectionContent: Hashable & Equatable {}

// MARK: - P2P.RTCIncomingMessage + Hashable, Equatable
extension P2P.RTCIncomingMessage: Hashable, Equatable where PeerConnectionContent: Hashable & Equatable {}
