import Foundation

// MARK: - P2P.RTCIncomingWalletInteraction
extension P2P {
	// FIXME: clean up, merge with P2P.IncomingMessage somehow, maybe we use `some`?
	public struct RTCIncomingWalletInteraction: Sendable, Hashable {
		public let connectionId: ConnectionPassword
		public let peerMessage: PeerConnectionMessage

		public struct PeerConnectionMessage: Sendable, Hashable {
			public let peerConnectionId: PeerConnectionID
			public let content: P2P.FromDapp.WalletInteraction
		}
	}
}

extension P2P.RTCIncomingMessage {
	public func unwrapResult() throws -> P2P.RTCIncomingWalletInteraction {
		try .init(
			connectionId: connectionId,
			peerMessage: .init(
				peerConnectionId: peerMessage.peerConnectionId,
				content: peerMessage.result.get().asDapp()
			)
		)
	}
}

extension P2P.RTCIncomingWalletInteraction {
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
