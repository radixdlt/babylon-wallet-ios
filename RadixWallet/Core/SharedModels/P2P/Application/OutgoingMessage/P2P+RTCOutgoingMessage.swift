// MARK: - P2P.RTCOutgoingMessage
extension P2P {
	/// A message to be sent to some peer over WebRTC
	/// it might be either a response to some original
	/// incoming request, or it might be a request initiated
	/// by our wallet.
	enum RTCOutgoingMessage: Sendable, Hashable {
		/// A response to some request that we received from `origin`,
		/// we will use `origin` to identify the RTC channel to send over.
		case response(Response, origin: Route)

		/// A request initiated by us, sent over RTC using `sendStrategy`.
		case request(Request, sendStrategy: Request.SendStrategy)

		/// A response to some request that we received from `origin`,
		/// we will use `origin` to identify the RTC channel to send over.
		enum Response: Sendable, Hashable, Encodable {
			/// Response back to Dapps
			case dapp(WalletToDappInteractionResponse)
		}

		/// A request initiated by us, sent over RTC using `SendStrategy`.
		enum Request: Sendable, Hashable, Encodable {
			/// Describes the strategy used to find a RTC peer to send a request to.
			enum SendStrategy: Sendable, Hashable, Equatable {
				/// Sends a request to ALL P2PLinks
				case broadcastToAllPeers

				/// Sends a request to ALL P2PLinks that have a specific `RadixConnectPurpose`
				case broadcastToAllPeersWith(purpose: RadixConnectPurpose)
			}

			/// e.g. for Ledger Nano interaction, `PeerConnectionID` is not known
			case connectorExtension(P2P.ConnectorExtension.Request)
		}
	}
}

extension P2P.RTCOutgoingMessage.Response {
	func encode(to encoder: Encoder) throws {
		switch self {
		case let .dapp(response):
			try response.encode(to: encoder)
		}
	}
}

extension P2P.RTCOutgoingMessage.Request {
	func encode(to encoder: Encoder) throws {
		switch self {
		case let .connectorExtension(request):
			try request.encode(to: encoder)
		}
	}
}
