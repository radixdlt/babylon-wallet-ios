import Address
import Foundation

public extension AccountList {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
		case account(id: AccountList.Row.State.ID, action: AccountList.Row.Action)
	}
}

public extension AccountList.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
	}
}

public extension AccountList.Action.InternalAction {
	enum UserAction: Equatable {
		case alertDismissed
		case loadAccounts
	}
}

public extension AccountList.Action {
	enum CoordinatingAction: Equatable {
		case displayAccountDetails(AccountList.Row.State)
		case copyAddress(Address)
		case loadAccounts
	}
}
