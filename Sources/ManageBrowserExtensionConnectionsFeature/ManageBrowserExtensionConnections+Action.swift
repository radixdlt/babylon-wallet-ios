import Foundation

// MARK: - ManageBrowserExtensionConnections.Action
public extension ManageBrowserExtensionConnections {
	enum Action: Equatable {
		case coordinate(CoordinateAction)
		case `internal`(InternalAction)
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
	}
}
