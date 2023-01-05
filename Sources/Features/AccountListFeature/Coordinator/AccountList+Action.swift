import Foundation
import Profile

// MARK: - AccountList.Action
public extension AccountList {
	// MARK: Action
	enum Action: Sendable, Equatable {
		case child(ChildAction)
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - AccountList.Action.ChildAction
public extension AccountList.Action {
	enum ChildAction: Sendable, Equatable {
		case account(id: AccountList.Row.State.ID, action: AccountList.Row.Action)
	}
}

// MARK: - AccountList.Action.ViewAction
public extension AccountList.Action {
	enum ViewAction: Sendable, Equatable {
		case viewAppeared
		case alertDismissButtonTapped
	}
}

// MARK: - AccountList.Action.InternalAction
public extension AccountList.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - AccountList.Action.InternalAction.SystemAction
public extension AccountList.Action.InternalAction {
	enum SystemAction: Sendable, Equatable {}
}

// MARK: - AccountList.Action.DelegateAction
public extension AccountList.Action {
	enum DelegateAction: Sendable, Equatable {
		case displayAccountDetails(AccountList.Row.State)
		case fetchPortfolioForAccounts
	}
}
