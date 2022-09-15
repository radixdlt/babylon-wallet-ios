import Foundation

public extension AccountList.Row {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
	}
}

public extension AccountList.Row.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
	}
}

public extension AccountList.Row.Action.InternalAction {
	enum UserAction: Equatable {
		case copyAddress
		case didSelect
	}
}
