import Foundation

// MARK: - ChooseAccounts.Row.Action
public extension ChooseAccounts.Row {
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
	}
}

// MARK: - ChooseAccounts.Row.Action.InternalAction
public extension ChooseAccounts.Row.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

// MARK: - ChooseAccounts.Row.Action.InternalAction.UserAction
public extension ChooseAccounts.Row.Action.InternalAction {
	enum UserAction: Equatable {
		case didSelect
	}
}

// MARK: - ChooseAccounts.Row.Action.InternalAction.SystemAction
public extension ChooseAccounts.Row.Action.InternalAction {
	enum SystemAction: Equatable {}
}

// MARK: - ChooseAccounts.Row.Action.CoordinatingAction
public extension ChooseAccounts.Row.Action {
	enum CoordinatingAction: Equatable {}
}
