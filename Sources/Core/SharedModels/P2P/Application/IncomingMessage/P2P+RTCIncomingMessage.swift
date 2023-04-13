import RadixConnectModels

extension P2P {
	/// Recipient of sender of an RTC message
	public struct RTCRoute: Sendable, Hashable {
		/// The PerPeerPairConnection password.
		public let connectionId: ConnectionPassword
		/// ID to a specific peer **connection** for some PerPeerPairConnection.
		public let peerConnectionId: PeerConnectionID

		public init(connectionId: ConnectionPassword, peerConnectionId: PeerConnectionID) {
			self.connectionId = connectionId
			self.peerConnectionId = peerConnectionId
		}
	}

	/// An incoming message over RTC from some `route`, might have failed
	/// or succeeded to receive and decode, which is why this contains a
	/// `result` and not an `P2P.RTCMessageFromPeer` directly.
	public struct RTCIncoXYZmingMessage: Sendable {
		public let result: Result<P2P.RTCMessageFromPeer, Error>
		public let route: RTCRoute
		public init(result: Result<P2P.RTCMessageFromPeer, Error>, route: RTCRoute) {
			self.result = result
			self.route = route
		}
	}
}
