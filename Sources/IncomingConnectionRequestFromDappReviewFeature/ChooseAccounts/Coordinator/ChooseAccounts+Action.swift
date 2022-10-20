import Foundation

// MARK: - ChooseAccounts.Action
public extension ChooseAccounts {
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
        case account(id: ChooseAccounts.Row.State.ID, action: ChooseAccounts.Row.Action)
	}
}

// MARK: - ChooseAccounts.Action.InternalAction
public extension ChooseAccounts.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

// MARK: - ChooseAccounts.Action.InternalAction.UserAction
public extension ChooseAccounts.Action.InternalAction {
	enum UserAction: Equatable {}
}

// MARK: - ChooseAccounts.Action.InternalAction.SystemAction
public extension ChooseAccounts.Action.InternalAction {
	enum SystemAction: Equatable {}
}

// MARK: - ChooseAccounts.Action.CoordinatingAction
public extension ChooseAccounts.Action {
	enum CoordinatingAction: Equatable {}
}
