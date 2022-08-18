import Foundation

public extension Home.AccountRow {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
	}
}

public extension Home.AccountRow.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

public extension Home.AccountRow.Action.InternalAction {
	enum UserAction: Equatable {}
}

public extension Home.AccountRow.Action.InternalAction {
	enum SystemAction: Equatable {}
}

public extension Home.AccountRow.Action {
	enum CoordinatingAction: Equatable {}
}
