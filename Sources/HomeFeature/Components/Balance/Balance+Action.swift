import Foundation

public extension Home.Balance {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
	}
}

public extension Home.Balance.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
	}
}

public extension Home.Balance.Action.InternalAction {
	enum UserAction: Equatable {
		case toggleVisibilityButtonTapped
	}
}
