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

	/// An incoming Dapp Request over RTC from some `route`, might have failed
	/// or succeeded to receive and decode, which is why this contains a
	/// `result` and not an `P2P.Dapp.Request` directly.
	public typealias RTCIncomingDappRequest = RTCIncomingMessageContainer<P2P.Dapp.Request>

	/// An incoming message over RTC from some `route`, might have failed
	/// or succeeded to receive and decode, which is why this contains a
	/// `result` and not an `P2P.RTCMessageFromPeer` directly.
	public struct RTCIncomingMessageContainer<Success: Sendable & Hashable>: Sendable, Hashable {
		public let result: Result<Success, Error>
		public let route: RTCRoute
		public init(result: Result<Success, Error>, route: RTCRoute) {
			self.result = result
			self.route = route
		}
	}
}

extension P2P.RTCIncomingMessageContainer {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		guard lhs.route == rhs.route else {
			return false
		}
		switch (lhs.result, rhs.result) {
		case let (.failure(lhsFailure), .failure(rhsFailure)):
			// FIXME: strongly type messages? to an Error type which is Hashable?
			return String(describing: lhsFailure) == String(describing: rhsFailure)
		case let (.success(lhsSuccess), .success(rhsSuccess)):
			return lhsSuccess == rhsSuccess

		default: return false
		}
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(route)
		switch result {
		case let .failure(error):
			hasher.combine(String(describing: error))
		case let .success(success):
			hasher.combine(success)
		}
	}

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
