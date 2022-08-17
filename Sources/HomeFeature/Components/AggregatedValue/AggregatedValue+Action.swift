import Foundation

public extension Home.AggregatedValue {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
	}
}

public extension Home.AggregatedValue.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
	}
}

public extension Home.AggregatedValue.Action.InternalAction {
	enum UserAction: Equatable {
		case toggleVisibilityButtonTapped
	}
}
