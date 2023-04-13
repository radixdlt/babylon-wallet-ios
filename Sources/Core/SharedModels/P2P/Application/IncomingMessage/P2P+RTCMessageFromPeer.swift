import RadixConnectModels

// MARK: - P2P.RTCMessageFromPeer
extension P2P {
	/// A successfully received and decoded message from a peer
	/// either a `response` or a `request`.
	public enum RTCMessageFromPeer: Sendable, Hashable {
		/// A response from a peer to some request we have sent over RTC
		case response(Response)

		/// A request coming from some peer over RTC
		case request(Request)

		/// A response from a peer to some request we have sent.
		public enum Response: Sendable, Hashable, Equatable, Decodable {
			case connectorExtension(P2P.ConnectorExtension.Response)
		}

		public enum Request: Sendable, Hashable, Equatable, Decodable {
			case dapp(P2P.Dapp.Request)
		}
	}
}

extension P2P.RTCMessageFromPeer.Request {
	public init(from decoder: Decoder) throws {
		self = try .dapp(.init(from: decoder))
	}
}

extension P2P.RTCMessageFromPeer.Response {
	public init(from decoder: Decoder) throws {
		self = try .connectorExtension(.init(from: decoder))
	}
}
