import Foundation

// MARK: - SignalingServerMessage.Incoming.FromSignalingServerItself.Notification
extension SignalingServerMessage.Incoming.FromSignalingServerItself {
	public enum Notification: String, Sendable, Hashable, Decodable, CustomStringConvertible {
		case remoteClientJustConnected
		case remoteClientDisconnected
		case remoteClientIsAlreadyConnected
	}
}

extension SignalingServerMessage.Incoming.FromSignalingServerItself.Notification {
	internal var isRemoteClientConnected: Bool {
		switch self {
		case .remoteClientDisconnected: return false
		case .remoteClientIsAlreadyConnected, .remoteClientJustConnected: return true
		}
	}

	internal var isRemoteClientJustConnected: Bool {
		switch self {
		case .remoteClientDisconnected, .remoteClientIsAlreadyConnected: return false
		case .remoteClientJustConnected: return true
		}
	}

	internal var isRemoteClientIsAlreadyConnected: Bool {
		switch self {
		case .remoteClientJustConnected, .remoteClientDisconnected: return false
		case .remoteClientIsAlreadyConnected: return true
		}
	}

	internal var remoteClientIsAlreadyConnected: Self? {
		guard case .remoteClientIsAlreadyConnected = self else {
			return nil
		}
		return self
	}

	internal var remoteClientJustConnected: Self? {
		guard case .remoteClientJustConnected = self else {
			return nil
		}
		return self
	}
}

extension SignalingServerMessage.Incoming.FromSignalingServerItself.Notification {
	public var description: String {
		rawValue
	}
}
