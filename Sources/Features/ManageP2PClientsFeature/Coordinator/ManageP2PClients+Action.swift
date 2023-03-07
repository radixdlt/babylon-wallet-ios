import FeaturePrelude
import NewConnectionFeature
import RadixConnectClient

// MARK: - ManageP2PClients.Action
extension ManageP2PClients {
	public enum Action: Sendable, Equatable {
		case child(ChildAction)
		case `internal`(InternalAction)
	}
}

extension ManageP2PClients.Action {
	public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
}

// MARK: - ManageP2PClients.Action.ChildAction
extension ManageP2PClients.Action {
	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationActionOf<ManageP2PClients.Destinations>)
		case connection(
			id: ConnectionPassword,
			action: ManageP2PClient.Action
		)
	}
}

// MARK: - ManageP2PClients.Action.ViewAction
extension ManageP2PClients.Action {
	public enum ViewAction: Sendable, Equatable {
		case task
		case addNewConnectionButtonTapped
	}
}

// MARK: - ManageP2PClients.Action.InternalAction
extension ManageP2PClients.Action {
	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - ManageP2PClients.Action.InternalAction.SystemAction
extension ManageP2PClients.Action.InternalAction {
	public enum SystemAction: Sendable, Equatable {
		case loadClientsResult(TaskResult<OrderedSet<P2PClient>>)
		case saveNewConnectionResult(TaskResult<P2PClient>)
		case deleteConnectionResult(TaskResult<ConnectionPassword>)
	}
}
