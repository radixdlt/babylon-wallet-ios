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
	public typealias RTCIncomingMessage = RTCIncomingMessageContainer<P2P.RTCMessageFromPeer>

	/// An incoming response over RTC from some `route`, might have failed
	/// or succeeded to receive and decode, which is why this contains a
	/// `result` and not an `P2P.RTCMessageFromPeer.Response` directly.
	public typealias RTCIncomingResponse = RTCIncomingMessageContainer<P2P.RTCMessageFromPeer.Response>

	/// An incoming request over RTC from some `route`, might have failed
	/// or succeeded to receive and decode, which is why this contains a
	/// `result` and not an `P2P.RTCMessageFromPeer.Request` directly.
	public typealias RTCIncomingRequest = RTCIncomingMessageContainer<P2P.RTCMessageFromPeer.Request>

	/// An incoming message over RTC from some `route`, might have failed
	/// or succeeded to receive and decode, which is why this contains a
	/// `result` and not an `P2P.RTCMessageFromPeer` directly.
	public struct RTCIncomingMessageContainer<Success: Sendable>: Sendable {
		public let result: Result<Success, Error>
		public let route: RTCRoute
		public init(result: Result<Success, Error>, route: RTCRoute) {
			self.result = result
			self.route = route
		}
	}
}

extension P2P.RTCIncomingMessageContainer {
	public func flatMap<NewSuccess>(
		_ transform: (Success) -> NewSuccess?
	) -> P2P.RTCIncomingMessageContainer<NewSuccess>? {
		switch result {
		case let .failure(error): return .init(result: .failure(error), route: route)
		case let .success(value):
			guard let transformed = transform(value) else {
				return nil
			}
			return .init(result: .success(transformed), route: route)
		}
	}
}
