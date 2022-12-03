import ComposableArchitecture
import Converse
import ConverseCommon
import Foundation
import NewConnectionFeature
import P2PConnectivityClient
import Profile
import SharedModels

// MARK: - ManageP2PClients.Action
public extension ManageP2PClients {
	enum Action: Sendable, Equatable {
		case child(ChildAction)
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

public extension ManageP2PClients.Action {
	static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
}

// MARK: - ManageP2PClients.Action.ChildAction
public extension ManageP2PClients.Action {
	enum ChildAction: Sendable, Equatable {
		case newConnection(NewConnection.Action)
		case connection(
			id: ManageP2PClient.State.ID,
			action: ManageP2PClient.Action
		)
	}
}

// MARK: - ManageP2PClients.Action.ViewAction
public extension ManageP2PClients.Action {
	enum ViewAction: Sendable, Equatable {
		case viewAppeared
		case dismissButtonTapped
		case addNewConnectionButtonTapped
	}
}

// MARK: - ManageP2PClients.Action.InternalAction
public extension ManageP2PClients.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - ManageP2PClients.Action.InternalAction.SystemAction
public extension ManageP2PClients.Action.InternalAction {
	enum SystemAction: Sendable, Equatable {
		case loadConnectionsResult(TaskResult<[P2P.ClientWithConnectionStatus]>)

		case successfullyOpenedConnection(Connection)
		case saveNewConnectionResult(TaskResult<P2P.ConnectedClient>)
		case deleteConnectionResult(TaskResult<P2PClient.ID>)
		case sendTestMessageResult(TaskResult<String>)
	}
}

// MARK: - ManageP2PClients.Action.DelegateAction
public extension ManageP2PClients.Action {
	enum DelegateAction: Sendable, Equatable {
		case dismiss
	}
}
