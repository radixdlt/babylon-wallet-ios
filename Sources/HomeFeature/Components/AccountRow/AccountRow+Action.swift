import Foundation

public extension Home.AccountRow {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
	}
}

public extension Home.AccountRow.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
	}
}

public extension Home.AccountRow.Action.InternalAction {
	enum UserAction: Equatable {
		case copyAddress
		case didSelect
	}
}
