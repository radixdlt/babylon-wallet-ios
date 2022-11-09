import Foundation
import Profile

// MARK: - AccountList.Action
public extension AccountList {
	// MARK: Action
	enum Action: Equatable {
		case child(ChildAction)
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
	}
}

// MARK: - AccountList.Action.ChildAction
public extension AccountList.Action {
	enum ChildAction: Equatable {
		case account(id: AccountList.Row.State.ID, action: AccountList.Row.Action)
	}
}

// MARK: - AccountList.Action.ViewAction
public extension AccountList.Action {
	enum ViewAction: Equatable {
		case viewAppeared
		case alertDismissButtonTapped
	}
}

// MARK: - AccountList.Action.InternalAction
public extension AccountList.Action {
	enum InternalAction: Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - AccountList.Action.InternalAction.SystemAction
public extension AccountList.Action.InternalAction {
	enum SystemAction: Equatable {}
}

// MARK: - AccountList.Action.CoordinatingAction
public extension AccountList.Action {
	enum CoordinatingAction: Equatable {
		case displayAccountDetails(AccountList.Row.State)
		case copyAddress(AccountAddress)
		case fetchPortfolioForAccounts
	}
}
