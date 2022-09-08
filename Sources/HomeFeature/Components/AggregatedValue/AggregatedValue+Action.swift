import Foundation

public extension Home.AggregatedValue {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
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

public extension Home.AggregatedValue.Action {
	enum CoordinatingAction: Equatable {
		case toggleIsCurrencyAmountVisible
	}
}
