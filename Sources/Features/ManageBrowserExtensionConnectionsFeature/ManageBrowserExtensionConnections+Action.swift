import BrowserExtensionsConnectivityClient
import ComposableArchitecture
import ConnectUsingPasswordFeature
import Converse
import ConverseCommon
import Foundation
import InputPasswordFeature
import Profile

// MARK: - ManageBrowserExtensionConnections.Action
public extension ManageBrowserExtensionConnections {
	enum Action: Equatable {
		case child(ChildAction)
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - ManageBrowserExtensionConnections.Action.ChildAction
public extension ManageBrowserExtensionConnections.Action {
	enum ChildAction: Equatable {
		case inputBrowserExtensionConnectionPassword(InputPassword.Action)
		case connectUsingPassword(ConnectUsingPassword.Action)
		case connection(
			id: ManageBrowserExtensionConnection.State.ID,
			action: ManageBrowserExtensionConnection.Action
		)
	}
}

// MARK: - ManageBrowserExtensionConnections.Action.ViewAction
public extension ManageBrowserExtensionConnections.Action {
	enum ViewAction: Equatable {
		case viewAppeared
		case dismissButtonTapped
		case addNewConnectionButtonTapped
		case dismissNewConnectionFlowButtonTapped
	}
}

// MARK: - ManageBrowserExtensionConnections.Action.InternalAction
public extension ManageBrowserExtensionConnections.Action {
	enum InternalAction: Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - ManageBrowserExtensionConnections.Action.InternalAction.SystemAction
public extension ManageBrowserExtensionConnections.Action.InternalAction {
	enum SystemAction: Equatable {
		case successfullyOpenedConnectionToBrowser(Connection)

		case initConnectionSecretsResult(TaskResult<ConnectionSecrets>)
		case loadConnectionsResult(TaskResult<[BrowserExtensionWithConnectionStatus]>)

		case saveNewConnectionResult(TaskResult<StatefulBrowserConnection>)

		case deleteConnectionResult(TaskResult<BrowserExtensionConnection.ID>)
		case sendTestMessageResult(TaskResult<String>)
	}
}

// MARK: - ManageBrowserExtensionConnections.Action.DelegateAction
public extension ManageBrowserExtensionConnections.Action {
	enum DelegateAction: Equatable {
		case dismiss
	}
}
