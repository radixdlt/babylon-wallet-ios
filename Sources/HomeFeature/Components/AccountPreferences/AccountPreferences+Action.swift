import Foundation

public extension Home.AccountPreferences {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
	}
}

public extension Home.AccountPreferences.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

public extension Home.AccountPreferences.Action.InternalAction {
	enum UserAction: Equatable {}
}

public extension Home.AccountPreferences.Action.InternalAction {
	enum SystemAction: Equatable {}
}

public extension Home.AccountPreferences.Action {
	enum CoordinatingAction: Equatable {}
}
