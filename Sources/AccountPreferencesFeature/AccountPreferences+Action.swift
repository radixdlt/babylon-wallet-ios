import Foundation

public extension AccountPreferences {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
	}
}

public extension AccountPreferences.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
	}
}

public extension AccountPreferences.Action.InternalAction {
	enum UserAction: Equatable {
		case dismissAccountPreferences
	}
}

public extension AccountPreferences.Action {
	enum CoordinatingAction: Equatable {
		case dismissAccountPreferences
	}
}
