import FeaturePrelude

// MARK: - AccountList.Row.Action
public extension AccountList.Row {
	// MARK: Action
	enum Action: Sendable, Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
	}
}

// MARK: - AccountList.Row.Action.ViewAction
public extension AccountList.Row.Action {
	enum ViewAction: Sendable, Equatable {
		case copyAddressButtonTapped
		case selected
	}
}

// MARK: - AccountList.Row.Action.InternalAction
public extension AccountList.Row.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
	}
}
