import ComposableArchitecture
import Converse
import ConverseCommon

// MARK: - ManageP2PClient.Action
public extension ManageP2PClient {
	enum Action: Sendable, Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case delegate(DelegateAction)
		case `internal`(InternalAction)
	}
}

// MARK: - ManageP2PClient.Action.ViewAction
public extension ManageP2PClient.Action {
	enum ViewAction: Sendable, Equatable {
		case deleteConnectionButtonTapped
		case sendTestMessageButtonTapped
		case viewAppeared
	}
}

public extension ManageP2PClient.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}

	enum DelegateAction: Sendable, Equatable {
		case deleteConnection
		case sendTestMessage
	}
}

// MARK: - ManageP2PClient.Action.InternalAction.SystemAction
public extension ManageP2PClient.Action.InternalAction {
	enum SystemAction: Sendable, Equatable {
		case connectionStatusResult(TaskResult<Connection.State>)
	}
}
