import FeaturePrelude

// MARK: - AccountList.Row.Action
extension AccountList.Row {
	// MARK: Action
	public enum Action: Sendable, Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
	}
}

// MARK: - AccountList.Row.Action.ViewAction
extension AccountList.Row.Action {
	public enum ViewAction: Sendable, Equatable {
		case copyAddressButtonTapped
		case selected
	}
}

// MARK: - AccountList.Row.Action.InternalAction
extension AccountList.Row.Action {
	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
	}
}
