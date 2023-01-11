import Foundation

// MARK: - SignalingServerMessage.Incoming.FromSignalingServerItself.Notification
public extension SignalingServerMessage.Incoming.FromSignalingServerItself {
	enum Notification: String, Sendable, Hashable, Decodable, CustomStringConvertible {
		case remoteClientJustConnected
		case remoteClientDisconnected
		case remoteClientIsAlreadyConnected
	}
}

internal extension SignalingServerMessage.Incoming.FromSignalingServerItself.Notification {
	var isRemoteClientConnected: Bool {
		switch self {
		case .remoteClientDisconnected: return false
		case .remoteClientIsAlreadyConnected, .remoteClientJustConnected: return true
		}
	}

	var isRemoteClientJustConnected: Bool {
		switch self {
		case .remoteClientDisconnected, .remoteClientIsAlreadyConnected: return false
		case .remoteClientJustConnected: return true
		}
	}

	var isRemoteClientIsAlreadyConnected: Bool {
		switch self {
		case .remoteClientJustConnected, .remoteClientDisconnected: return false
		case .remoteClientIsAlreadyConnected: return true
		}
	}

	var remoteClientIsAlreadyConnected: Self? {
		guard case .remoteClientIsAlreadyConnected = self else {
			return nil
		}
		return self
	}

	var remoteClientJustConnected: Self? {
		guard case .remoteClientJustConnected = self else {
			return nil
		}
		return self
	}
}

public extension SignalingServerMessage.Incoming.FromSignalingServerItself.Notification {
	var description: String {
		rawValue
	}
}
