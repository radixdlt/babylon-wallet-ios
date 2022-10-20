import Foundation
import Profile

// MARK: - AccountList.Action
public extension AccountList {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
		case account(id: AccountList.Row.State.ID, action: AccountList.Row.Action)
	}
}

// MARK: - AccountList.Action.InternalAction
public extension AccountList.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

// MARK: - AccountList.Action.InternalAction.UserAction
public extension AccountList.Action.InternalAction {
	enum UserAction: Equatable {
		case alertDismissed
	}
}

// MARK: - AccountList.Action.InternalAction.SystemAction
public extension AccountList.Action.InternalAction {
	enum SystemAction: Equatable {
		case fetchPortfolioForAccounts
	}
}

// MARK: - AccountList.Action.CoordinatingAction
public extension AccountList.Action {
	enum CoordinatingAction: Equatable {
		case displayAccountDetails(AccountList.Row.State)
		case copyAddress(AccountAddress)
		case fetchPortfolioForAccounts
	}
}
