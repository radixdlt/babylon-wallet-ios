import CreateAccount
import Foundation

public extension Home {
	// MARK: Action
	enum Action: Equatable {
		case accountList(Home.AccountList.Action)
		case aggregatedValue(Home.AggregatedValue.Action)
		case header(Home.Header.Action)
		case visitHub(Home.VisitHub.Action)
		case accountPreferences(Home.AccountPreferences.Action)
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
		case accountDetails(Home.AccountDetails.Action)
		case transfer(Home.Transfer.Action)
		case createAccount(CreateAccount.Action)
	}
}

public extension Home.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
	}
}

public extension Home.Action.InternalAction {
	enum UserAction: Equatable {
		case createAccountButtonTapped
	}
}

public extension Home.Action {
	enum CoordinatingAction: Equatable {
		case displaySettings
		case copyAddress(Home.AccountRow.State)
	}
}
