import Foundation

// MARK: - AggregatedValue.Action
public extension AggregatedValue {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
	}
}

// MARK: - AggregatedValue.Action.InternalAction
public extension AggregatedValue.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
	}
}

// MARK: - AggregatedValue.Action.InternalAction.UserAction
public extension AggregatedValue.Action.InternalAction {
	enum UserAction: Equatable {
		case toggleVisibilityButtonTapped
	}
}

// MARK: - AggregatedValue.Action.CoordinatingAction
public extension AggregatedValue.Action {
	enum CoordinatingAction: Equatable {
		case toggleIsCurrencyAmountVisible
	}
}
