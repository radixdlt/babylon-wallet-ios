import Foundation

// MARK: - AccountPreferences.Action
public extension AccountPreferences {
	// MARK: Action
	enum Action: Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - AccountPreferences.Action.ViewAction
public extension AccountPreferences.Action {
	enum ViewAction: Equatable {
		case dismissButtonTapped
	}
}

// MARK: - AccountPreferences.Action.InternalAction
public extension AccountPreferences.Action {
	enum InternalAction: Equatable {
		case view(ViewAction)
	}
}

// MARK: - AccountPreferences.Action.DelegateAction
public extension AccountPreferences.Action {
	enum DelegateAction: Equatable {
		case dismissAccountPreferences
	}
}
