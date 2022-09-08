import Foundation
import Profile

public extension Home.AccountList {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
		case account(id: Home.AccountRow.State.ID, action: Home.AccountRow.Action)
	}
}

public extension Home.AccountList.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
	}
}

public extension Home.AccountList.Action.InternalAction {
	enum UserAction: Equatable {
		case alertDismissed
		case loadAccounts
	}
}

public extension Home.AccountList.Action {
	enum CoordinatingAction: Equatable {
		case displayAccountDetails(Home.AccountRow.State)
		case copyAddress(Profile.Account.Address)
		case loadAccounts
	}
}
