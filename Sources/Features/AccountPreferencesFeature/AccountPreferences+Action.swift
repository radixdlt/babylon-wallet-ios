import Foundation

// MARK: - AccountPreferences.Action
public extension AccountPreferences {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
	}
}

// MARK: - AccountPreferences.Action.InternalAction
public extension AccountPreferences.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
	}
}

// MARK: - AccountPreferences.Action.InternalAction.UserAction
public extension AccountPreferences.Action.InternalAction {
	enum UserAction: Equatable {
		case dismissAccountPreferences
	}
}

// MARK: - AccountPreferences.Action.CoordinatingAction
public extension AccountPreferences.Action {
	enum CoordinatingAction: Equatable {
		case dismissAccountPreferences
	}
}
