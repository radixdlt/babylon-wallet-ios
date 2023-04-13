import Foundation

// MARK: - P2P.RTCIncomingWalletInteraction
extension P2P {
	// FIXME: clean up, merge with P2P.IncomingMessage somehow, maybe we use `some`?
	public struct RTCIncomingWalletInteraction: Sendable, Hashable {
//		public let connectionId: ConnectionPassword
//		public let peerMessage: PeerConnectionMessage
//
//		public struct PeerConnectionMessage: Sendable, Hashable {
//			public let peerConnectionId: PeerConnectionID
//			public let content: P2P.FromDapp.WalletInteraction
//		}
		public let origin: RTCRoute
		public let request: P2P.FromDapp.WalletInteraction
	}
}

extension P2P.RTCMessageFromPeer {
	public func asDappRequest() throws -> P2P.FromDapp.WalletInteraction {
		guard case let .request(.dapp(requestFromDapp), _) = self else {
			throw WrongRequestType()
		}

		return requestFromDapp
	}
}

extension P2P.RTCIncoXYZmingMessage {
	public func unwrapResult() throws -> P2P.RTCIncomingWalletInteraction {
		try .init(
			origin: route,
			request: result.get().asDappRequest()
		)
	}
}

extension P2P.RTCIncomingWalletInteraction {
	/// Transforms an incoming message FromDapp to an OutgoingMessage to Dapp
	/// by preserving the RTCClient and PeerConnection IDs
	public func toDapp(
		response: P2P.ToDapp.WalletInteractionResponse
	) -> P2P.RTCOutgoingMessage {
		.response(.dapp(response), origin: origin)
	}
}

extension P2P.RTCOutgoingMessage {
	public func toDapp() throws -> P2P.ToDapp.WalletInteractionResponse {
		guard case let .response(.dapp(response), _) = self else {
			throw WrongResponseType()
		}

		return response
	}
}
