import Foundation

public extension AggregatedValue {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
	}
}

public extension AggregatedValue.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
	}
}

public extension AggregatedValue.Action.InternalAction {
	enum UserAction: Equatable {
		case toggleVisibilityButtonTapped
	}
}

public extension AggregatedValue.Action {
	enum CoordinatingAction: Equatable {
		case toggleIsCurrencyAmountVisible
	}
}
