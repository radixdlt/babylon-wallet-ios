import Foundation

// MARK: - AccountList.Row.Action
public extension AccountList.Row {
	// MARK: Action
	enum Action: Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
	}
}

// MARK: - AccountList.Row.Action.ViewAction
public extension AccountList.Row.Action {
	enum ViewAction: Equatable {
		case copyAddressButtonTapped
		case selected
	}
}

// MARK: - AccountList.Row.Action.InternalAction
public extension AccountList.Row.Action {
	enum InternalAction: Equatable {
		case view(ViewAction)
	}
}
