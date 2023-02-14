import FeaturePrelude

// MARK: - AggregatedValue.Action
extension AggregatedValue {
	// MARK: Action
	public enum Action: Sendable, Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - AggregatedValue.Action.ViewAction
extension AggregatedValue.Action {
	public enum ViewAction: Sendable, Equatable {
		case toggleVisibilityButtonTapped
	}
}

// MARK: - AggregatedValue.Action.InternalAction
extension AggregatedValue.Action {
	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
	}
}

// MARK: - AggregatedValue.Action.DelegateAction
extension AggregatedValue.Action {
	public enum DelegateAction: Sendable, Equatable {
		case toggleIsCurrencyAmountVisible
	}
}
