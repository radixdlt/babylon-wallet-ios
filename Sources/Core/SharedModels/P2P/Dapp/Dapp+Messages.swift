import Foundation

// MARK: - P2P.RTCIncomingWalletInteraction
extension P2P {
	public struct RTCIncomingWalletInteraction: Sendable, Hashable {
		public let origin: RTCRoute
		public let request: P2P.Dapp.Request
	}
}

extension P2P.RTCMessageFromPeer {
	public func asDappRequest() throws -> P2P.Dapp.Request {
		guard case let .request(.dapp(requestFromDapp)) = self else {
			throw WrongRequestType()
		}

		return requestFromDapp
	}
}

extension P2P.RTCIncomingMessage {
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
		response: P2P.Dapp.Response
	) -> P2P.RTCOutgoingMessage {
		.response(.dapp(response), origin: origin)
	}
}

extension P2P.RTCOutgoingMessage {
	public func toDapp() throws -> P2P.Dapp.Response {
		guard case let .response(.dapp(response), _) = self else {
			throw WrongResponseType()
		}

		return response
	}
}
