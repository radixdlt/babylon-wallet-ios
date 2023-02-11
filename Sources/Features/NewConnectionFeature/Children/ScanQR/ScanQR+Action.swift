import FeaturePrelude
import P2PModels

// MARK: - ScanQR.Action
extension ScanQR {
	public enum Action: Sendable, Equatable {
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

extension ScanQR.Action {
	public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
}

// MARK: - ScanQR.Action.ViewAction
extension ScanQR.Action {
	public enum ViewAction: Sendable, Equatable {
		case scanResult(TaskResult<String>)
		#if os(macOS) || (os(iOS) && targetEnvironment(simulator))
		case macInputConnectionPasswordChanged(String)
		case macConnectButtonTapped
		#endif // macOS
	}
}

// MARK: - ScanQR.Action.InternalAction
extension ScanQR.Action {
	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - ScanQR.Action.SystemAction
extension ScanQR.Action {
	public enum SystemAction: Sendable, Equatable {
		case connectionSecretsFromScannedStringResult(TaskResult<ConnectionSecrets>)
	}
}

// MARK: - ScanQR.Action.DelegateAction
extension ScanQR.Action {
	public enum DelegateAction: Sendable, Equatable {
		case connectionSecretsFromScannedQR(ConnectionSecrets)
	}
}
