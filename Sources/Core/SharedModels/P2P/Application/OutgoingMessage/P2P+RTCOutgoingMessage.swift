import RadixConnectModels

// MARK: - P2P.RTCOutgoingMessage
extension P2P {
	/// A message to be sent to some peer over WebRTC
	/// it might be either a response to some original
	/// incoming request, or it might be a request initiated
	/// by our wallet.
	public enum RTCOutgoingMessage: Sendable, Hashable {
		/// A response to some request that we received from `origin`,
		/// we will use `origin` to identify the RTC channel to send over.
		case response(Response, origin: RTCRoute)

		/// A request initiated by us, sent over RTC using `sendStrategy`.
		case request(Request, sendStrategy: Request.SendStrategy)

		/// A response to some request that we received from `origin`,
		/// we will use `origin` to identify the RTC channel to send over.
		public enum Response: Sendable, Hashable, Encodable {
			/// Response back to Dapps
			case dapp(P2P.ToDapp.WalletInteractionResponse)
		}

		/// A request initiated by us, sent over RTC using `SendStrategy`.
		public enum Request: Sendable, Hashable, Encodable {
			/// Describes the strategy used to find a RTC peer to send a request to.
			public enum SendStrategy: Sendable, Hashable, Equatable {
				/// Sends a request to ALL P2PLinks
				case broadcastToAllPeers
			}

			/// e.g. for Ledger Nano interaction, `PeerConnectionID` is not known
			case connectorExtension(P2P.ToConnectorExtension)
		}
	}
}

extension P2P.RTCOutgoingMessage.Response {
	public func encode(to encoder: Encoder) throws {
		switch self {
		case let .dapp(response):
			try response.encode(to: encoder)
		}
	}
}
