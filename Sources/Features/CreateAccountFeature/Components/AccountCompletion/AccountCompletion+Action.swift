import Foundation

// MARK: - AccountCompletion.Action
public extension AccountCompletion {
	// MARK: Action
	enum Action: Sendable, Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - AccountCompletion.Action.ViewAction
public extension AccountCompletion.Action {
	enum ViewAction: Sendable, Equatable {
		case goToDestination
	}
}

// MARK: - AccountCompletion.Action.InternalAction
public extension AccountCompletion.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - AccountCompletion.Action.InternalAction.SystemAction
public extension AccountCompletion.Action.InternalAction {
	enum SystemAction: Sendable, Equatable {}
}

// MARK: - AccountCompletion.Action.DelegateAction
public extension AccountCompletion.Action {
	enum DelegateAction: Sendable, Equatable {
		case displayHome
		case displayChooseAccounts
	}
}
