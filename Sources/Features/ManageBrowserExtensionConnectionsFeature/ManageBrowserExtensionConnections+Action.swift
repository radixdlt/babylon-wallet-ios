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
		case coordinate(CoordinateAction)
		case `internal`(InternalAction)

		case inputBrowserExtensionConnectionPassword(InputPassword.Action)
		case connectUsingPassword(ConnectUsingPassword.Action)
	}
}

public extension ManageBrowserExtensionConnections.Action {
	enum CoordinateAction: Equatable {
		case dismiss
	}

	enum InternalAction: Equatable {
		case user(UserAction)
		case coordinate(CoordinateAction)
		case system(SystemAction)
	}
}

// MARK: - ManageBrowserExtensionConnections.Action.InternalAction.CoordinateAction
public extension ManageBrowserExtensionConnections.Action.InternalAction {
	enum CoordinateAction: Equatable {
		case initConnectionSecretsResult(TaskResult<ConnectionSecrets>)
		case loadConnectionsFromProfile
		case loadConnectionsFromProfileResult(TaskResult<[BrowserExtensionConnectionWithState]>)

		case saveNewConnectionInProfile(BrowserExtensionConnectionWithState)
		case saveNewConnectionInProfileResult(TaskResult<BrowserExtensionConnectionWithState>)
	}
}

// MARK: - ManageBrowserExtensionConnections.Action.InternalAction.SystemAction
public extension ManageBrowserExtensionConnections.Action.InternalAction {
	enum SystemAction: Equatable {
		case viewDidAppear
		case successfullyOpenedConnectionToBrowser(Connection)
	}
}

// MARK: - ManageBrowserExtensionConnections.Action.UserAction
public extension ManageBrowserExtensionConnections.Action {
	enum UserAction: Equatable {
		case dismiss
		case addNewConnection
		case dismissNewConnectionFlow
	}
}
