import Foundation

// MARK: - SignalingServerMessage.Incoming
extension SignalingServerMessage {
	public enum Incoming: Sendable, Hashable, Decodable, CustomStringConvertible {
		case fromSignalingServerItself(FromSignalingServerItself)
		case fromRemoteClientOriginally(FromRemoteClientOriginally)
	}
}

extension SignalingServerMessage.Incoming {
	public var description: String {
		switch self {
		case let .fromSignalingServerItself(value):
			return "fromSignalingServerItself(\(value))"
		case let .fromRemoteClientOriginally(value):
			return "fromRemoteClientOriginally(\(String(describing: value)))"
		}
	}
}

extension SignalingServerMessage.Incoming {
	public typealias RequestId = String
	public typealias FromRemoteClientOriginally = RPCMessage
	public enum FromSignalingServerItself: Sendable, Hashable, CustomStringConvertible {
		case notification(Notification)
		case responseForRequest(ResponseForRequest)
	}
}

extension SignalingServerMessage.Incoming.FromSignalingServerItself {
	public var description: String {
		switch self {
		case let .notification(notification):
			return "notification(\(notification))"
		case let .responseForRequest(responseForRequest):
			return "responseForRequest(\(responseForRequest))"
		}
	}
}

extension SignalingServerMessage.Incoming.FromSignalingServerItself {
	public var responseForRequest: ResponseForRequest? {
		switch self {
		case let .responseForRequest(responseForRequest):
			return responseForRequest
		case .notification:
			return nil
		}
	}

	public var notification: Notification? {
		switch self {
		case let .notification(value):
			return value
		case .responseForRequest:
			return nil
		}
	}
}

extension SignalingServerMessage.Incoming {
	public var fromSignalingServerItself: FromSignalingServerItself? {
		switch self {
		case let .fromSignalingServerItself(value): return value
		case .fromRemoteClientOriginally: return nil
		}
	}

	public var fromRemoteClientOriginally: RPCMessage? {
		switch self {
		case let .fromRemoteClientOriginally(value): return value
		case .fromSignalingServerItself: return nil
		}
	}

	public var responseForRequest: FromSignalingServerItself.ResponseForRequest? {
		fromSignalingServerItself?.responseForRequest
	}

	public var notification: FromSignalingServerItself.Notification? {
		fromSignalingServerItself?.notification
	}

	public var rtcAnswerRPCMessageFromRemoteClient: RPCMessage? {
		guard
			let rpcMessage = fromRemoteClientOriginally,
			rpcMessage.method == .answer
		else {
			return nil
		}
		return rpcMessage
	}

	public var rtcOfferRPCMessageFromRemoteClient: RPCMessage? {
		guard
			let rpcMessage = fromRemoteClientOriginally,
			rpcMessage.method == .offer
		else {
			return nil
		}
		return rpcMessage
	}

	public var rtcICECandidateRPCMessageFromRemoteClient: RPCMessage? {
		guard
			let rpcMessage = fromRemoteClientOriginally,
			rpcMessage.method == .iceCandidate
		else {
			return nil
		}
		return rpcMessage
	}
}

extension SignalingServerMessage.Incoming {
	public var isRemoteClientConnected: Bool {
		guard let notification = notification else { return false }
		return notification.isRemoteClientConnected
	}

	public var remoteClientIsAlreadyConnected: Self? {
		fromSignalingServerItself?.remoteClientIsAlreadyConnected.map { .fromSignalingServerItself($0) }
	}

	public var remoteClientJustConnected: Self? {
		fromSignalingServerItself?.remoteClientJustConnected.map { .fromSignalingServerItself($0) }
	}
}

extension SignalingServerMessage.Incoming.FromSignalingServerItself {
	public var isRemoteClientConnected: Bool {
		guard let notification = notification else { return false }
		return notification.isRemoteClientConnected
	}

	public var isRemoteClientJustConnected: Bool {
		guard let notification = notification else { return false }
		return notification.isRemoteClientJustConnected
	}

	public var isRemoteClientIsAlreadyConnected: Bool {
		guard let notification = notification else { return false }
		return notification.isRemoteClientIsAlreadyConnected
	}

	public var remoteClientIsAlreadyConnected: Self? {
		notification?.remoteClientIsAlreadyConnected.map { .notification($0) }
	}

	public var remoteClientJustConnected: Self? {
		notification?.remoteClientJustConnected.map { .notification($0) }
	}
}
