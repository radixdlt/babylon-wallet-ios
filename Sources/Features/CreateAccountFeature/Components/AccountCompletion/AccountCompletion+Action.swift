import Foundation

// MARK: - AccountCompletion.Action
public extension AccountCompletion {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
	}
}

// MARK: - AccountCompletion.Action.InternalAction
public extension AccountCompletion.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

// MARK: - AccountCompletion.Action.InternalAction.UserAction
public extension AccountCompletion.Action.InternalAction {
	enum UserAction: Equatable {}
}

// MARK: - AccountCompletion.Action.InternalAction.SystemAction
public extension AccountCompletion.Action.InternalAction {
	enum SystemAction: Equatable {}
}

// MARK: - AccountCompletion.Action.CoordinatingAction
public extension AccountCompletion.Action {
	enum CoordinatingAction: Equatable {}
}
