// MARK: - P2P.RTCMessageFromPeer
extension P2P {
	/// A successfully received and decoded message from a peer
	/// either a `response` or a `request`.
	enum RTCMessageFromPeer: Sendable, Hashable {
		/// A response from a peer to some request we have sent over RTC
		case response(Response)

		/// A request coming from some peer over RTC
		case request(Request)

		/// A response from a peer to some request we have sent.
		enum Response: Sendable, Hashable, Equatable, Decodable {
			case connectorExtension(P2P.ConnectorExtension.Response)
		}

		enum Request: Sendable, Hashable, Equatable {
			case dapp(DappToWalletInteractionUnvalidated)
		}
	}
}

extension P2P.RTCMessageFromPeer.Response {
	init(from decoder: Decoder) throws {
		self = try .connectorExtension(.init(from: decoder))
	}
}
