import ComposableArchitecture
import ConnectUsingPasswordFeature
import Converse
import ConverseCommon
import Foundation
import InputPasswordFeature
import P2PConnectivityClient
import Profile
import SharedModels

// MARK: - ManageP2PClients.Action
public extension ManageP2PClients {
	enum Action: Equatable {
		case child(ChildAction)
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - ManageP2PClients.Action.ChildAction
public extension ManageP2PClients.Action {
	enum ChildAction: Equatable {
		case inputP2PConnectionPassword(InputPassword.Action)
		case connectUsingPassword(ConnectUsingPassword.Action)
		case connection(
			id: ManageP2PClient.State.ID,
			action: ManageP2PClient.Action
		)
	}
}

// MARK: - ManageP2PClients.Action.ViewAction
public extension ManageP2PClients.Action {
	enum ViewAction: Equatable {
		case viewAppeared
		case dismissButtonTapped
		case addNewConnectionButtonTapped
		case dismissNewConnectionFlowButtonTapped
	}
}

// MARK: - ManageP2PClients.Action.InternalAction
public extension ManageP2PClients.Action {
	enum InternalAction: Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - ManageP2PClients.Action.InternalAction.SystemAction
public extension ManageP2PClients.Action.InternalAction {
	enum SystemAction: Equatable {
		case successfullyOpenedConnection(Connection)

		case initConnectionSecretsResult(TaskResult<ConnectionSecrets>)
		case loadConnectionsResult(TaskResult<[P2P.ClientWithConnectionStatus]>)

		case saveNewConnectionResult(TaskResult<P2P.ConnectedClient>)

		case deleteConnectionResult(TaskResult<P2PClient.ID>)
		case sendTestMessageResult(TaskResult<String>)
	}
}

// MARK: - ManageP2PClients.Action.DelegateAction
public extension ManageP2PClients.Action {
	enum DelegateAction: Equatable {
		case dismiss
	}
}
