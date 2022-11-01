import Foundation
import InputPasswordFeature

// MARK: - ManageBrowserExtensionConnections.Action
public extension ManageBrowserExtensionConnections {
	enum Action: Equatable {
		case coordinate(CoordinateAction)
		case `internal`(InternalAction)

		case inputBrowserExtensionConnectionPassword(InputPassword.Action)
	}
}

public extension ManageBrowserExtensionConnections.Action {
	enum CoordinateAction: Equatable {
		case dismiss
	}

	enum InternalAction: Equatable {
		case user(UserAction)
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
