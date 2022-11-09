import Foundation

// MARK: - AggregatedValue.Action
public extension AggregatedValue {
	// MARK: Action
	enum Action: Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - AggregatedValue.Action.ViewAction
public extension AggregatedValue.Action {
	enum ViewAction: Equatable {
		case toggleVisibilityButtonTapped
	}
}

// MARK: - AggregatedValue.Action.InternalAction
public extension AggregatedValue.Action {
	enum InternalAction: Equatable {
		case view(ViewAction)
	}
}

// MARK: - AggregatedValue.Action.DelegateAction
public extension AggregatedValue.Action {
	enum DelegateAction: Equatable {
		case toggleIsCurrencyAmountVisible
	}
}
