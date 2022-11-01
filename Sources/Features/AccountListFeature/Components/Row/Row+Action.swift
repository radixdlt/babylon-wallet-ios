import Foundation

// MARK: - AccountList.Row.Action
public extension AccountList.Row {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
	}
}

// MARK: - AccountList.Row.Action.InternalAction
public extension AccountList.Row.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
	}
}

// MARK: - AccountList.Row.Action.InternalAction.UserAction
public extension AccountList.Row.Action.InternalAction {
	enum UserAction: Equatable {
		case copyAddress
		case didSelect
	}
}
