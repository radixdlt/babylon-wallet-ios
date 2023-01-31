import FeaturePrelude
import P2PConnection

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
		#if DEBUG
		case sendTestMessageButtonTapped
		#endif
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
		#if DEBUG
		case sendTestMessage
		#endif
	}
}

// MARK: - ManageP2PClient.Action.InternalAction.SystemAction
public extension ManageP2PClient.Action.InternalAction {
	enum SystemAction: Sendable, Equatable {
		case connectionStatusResult(TaskResult<ConnectionStatus>)
		#if DEBUG
		case webSocketStatusResult(TaskResult<WebSocketState>)
		case dataChannelStateResult(TaskResult<DataChannelState>)
		#endif
	}
}
