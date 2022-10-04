import Foundation

// MARK: - Settings.Action
public extension Settings {
	// MARK: Action
	enum Action: Equatable {
		case coordinate(CoordinatingAction)
		case `internal`(InternalAction)
	}
}

public extension Settings.Action {
	enum CoordinatingAction: Equatable {
		case dismissSettings
	}

	enum InternalAction: Equatable {
		case user(UserAction)
	}
}

// MARK: - Settings.Action.InternalAction.UserAction
public extension Settings.Action.InternalAction {
	enum UserAction: Equatable {
		case dismissSettings
	}
}
