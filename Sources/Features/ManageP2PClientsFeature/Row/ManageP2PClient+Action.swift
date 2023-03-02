import FeaturePrelude

// MARK: - ManageP2PClient.Action
extension ManageP2PClient {
	public enum Action: Sendable, Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case delegate(DelegateAction)
		case `internal`(InternalAction)
	}
}

// MARK: - ManageP2PClient.Action.ViewAction
extension ManageP2PClient.Action {
	public enum ViewAction: Sendable, Equatable {
		case deleteConnectionButtonTapped
		case viewAppeared
	}
}

extension ManageP2PClient.Action {
	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}

	public enum DelegateAction: Sendable, Equatable {
		case deleteConnection
	}
}

// MARK: - ManageP2PClient.Action.InternalAction.SystemAction
extension ManageP2PClient.Action.InternalAction {
	public enum SystemAction: Sendable, Equatable {
//		case connectionStatusResult(TaskResult<ConnectionStatus>)
	}
}
