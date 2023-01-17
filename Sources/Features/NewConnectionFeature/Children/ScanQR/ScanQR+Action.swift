import FeaturePrelude
import P2PModels

// MARK: - ScanQR.Action
public extension ScanQR {
	enum Action: Sendable, Equatable {
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

public extension ScanQR.Action {
	static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
}

// MARK: - ScanQR.Action.ViewAction
public extension ScanQR.Action {
	enum ViewAction: Sendable, Equatable {
		case scanResult(TaskResult<String>)
		#if os(macOS) || (os(iOS) && targetEnvironment(simulator))
		case macInputConnectionPasswordChanged(String)
		case macConnectButtonTapped
		#endif // macOS
	}
}

// MARK: - ScanQR.Action.InternalAction
public extension ScanQR.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - ScanQR.Action.SystemAction
public extension ScanQR.Action {
	enum SystemAction: Sendable, Equatable {
		case connectionSecretsFromScannedStringResult(TaskResult<ConnectionSecrets>)
	}
}

// MARK: - ScanQR.Action.DelegateAction
public extension ScanQR.Action {
	enum DelegateAction: Sendable, Equatable {
		case connectionSecretsFromScannedQR(ConnectionSecrets)
	}
}
