
extension P2P {
	enum Route: Sendable, Hashable {
		case wallet
		case rtc(RTCRoute)
		case deepLink(SessionId)

		var isDeepLink: Bool {
			if case .deepLink = self {
				return true
			}
			return false
		}
	}

	/// Recipient of sender of an RTC message
	struct RTCRoute: Sendable, Hashable {
		/// The PerPeerPairConnection
		let p2pLink: P2PLink
		/// The PerPeerPairConnection password.
		var connectionId: RadixConnectPassword { p2pLink.connectionPassword }
		/// ID to a specific peer **connection** for some PerPeerPairConnection.
		let peerConnectionId: PeerConnectionID

		init(p2pLink: P2PLink, peerConnectionId: PeerConnectionID) {
			self.p2pLink = p2pLink
			self.peerConnectionId = peerConnectionId
		}
	}

	/// An incoming message over RTC from some `route`, might have failed
	/// or succeeded to receive and decode, which is why this contains a
	/// `result` and not an `P2P.RTCMessageFromPeer` directly.
	typealias RTCIncomingMessage = RTCIncomingMessageContainer<P2P.RTCMessageFromPeer>

	/// An incoming Dapp Request over RTC from some `route`, might have failed
	/// or succeeded to receive and decode, which is why this contains a
	/// `result` and not an `DappToWalletInteraction` directly.
	typealias RTCIncomingDappNonValidatedRequest = RTCIncomingMessageContainer<DappToWalletInteractionUnvalidated>

	/// An incoming message over RTC from some `route`, might have failed
	/// or succeeded to receive and decode, which is why this contains a
	/// `result` and not an `P2P.RTCMessageFromPeer` directly.
	struct RTCIncomingMessageContainer<Success: Sendable & Hashable>: Sendable, Hashable {
		let result: Result<Success, Error>
		let route: Route
		let originRequiresValidation: Bool

		init(result: Result<Success, Error>, route: Route, originRequiresValidation: Bool) {
			self.result = result
			self.route = route
			self.originRequiresValidation = originRequiresValidation
		}
	}
}

extension P2P.RTCIncomingMessageContainer {
	static func == (lhs: Self, rhs: Self) -> Bool {
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

	func hash(into hasher: inout Hasher) {
		hasher.combine(route)
		switch result {
		case let .failure(error):
			hasher.combine(String(describing: error))
		case let .success(success):
			hasher.combine(success)
		}
	}

	func unpackMap<NewSuccess>(
		_ transform: (Success) -> NewSuccess?
	) -> P2P.RTCIncomingMessageContainer<NewSuccess>? {
		switch result {
		case let .failure(error): return .init(result: .failure(error), route: route, originRequiresValidation: originRequiresValidation)
		case let .success(value):
			guard let transformed = transform(value) else {
				return nil
			}
			return .init(result: .success(transformed), route: route, originRequiresValidation: originRequiresValidation)
		}
	}
}
