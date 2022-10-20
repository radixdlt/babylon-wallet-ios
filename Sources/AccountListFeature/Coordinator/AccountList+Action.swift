import Profile
import Foundation

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
	}
}

// MARK: - AccountList.Action.InternalAction.UserAction
public extension AccountList.Action.InternalAction {
	enum UserAction: Equatable {
		case alertDismissed
		case loadAccounts
	}
}

// MARK: - AccountList.Action.CoordinatingAction
public extension AccountList.Action {
	enum CoordinatingAction: Equatable {
		case displayAccountDetails(AccountList.Row.State)
		case copyAddress(AccountAddress)
		case loadAccounts
	}
}
