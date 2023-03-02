import FeaturePrelude

// MARK: - NewConnection.Action
extension NewConnection {
	public enum Action: Sendable, Equatable {
		case child(ChildAction)
		static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - NewConnection.Action.ChildAction
extension NewConnection.Action {
	public enum ChildAction: Sendable, Equatable {
		case cameraPermission(CameraPermission.Action)
		case localNetworkPermission(LocalNetworkPermission.Action)
		case scanQR(ScanQR.Action)
		case connectUsingSecrets(ConnectUsingSecrets.Action)
	}
}

// MARK: - NewConnection.Action.ViewAction
extension NewConnection.Action {
	public enum ViewAction: Sendable, Equatable {
		case dismissButtonTapped
	}
}

// MARK: - NewConnection.Action.InternalAction
extension NewConnection.Action {
	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - NewConnection.Action.SystemAction
extension NewConnection.Action {
	public enum SystemAction: Sendable, Equatable {}
}

// MARK: - NewConnection.Action.DelegateAction
extension NewConnection.Action {
	public enum DelegateAction: Sendable, Equatable {
		case dismiss
		case newConnection(P2PClient)
	}
}
