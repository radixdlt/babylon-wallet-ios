import Common
import Foundation

public extension Home {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)

		case accountList(Home.AccountList.Action)
		case aggregatedValue(Home.AggregatedValue.Action)
		case header(Home.Header.Action)
		case visitHub(Home.VisitHub.Action)
		case accountPreferences(Home.AccountPreferences.Action)
		case accountDetails(Home.AccountDetails.Action)
		case transfer(Home.Transfer.Action)
		case createAccount(Home.CreateAccount.Action)
	}
}

public extension Home.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

public extension Home.Action.InternalAction {
	enum UserAction: Equatable {
		case createAccountButtonTapped
	}
}

public extension Home.Action.InternalAction {
	enum SystemAction: Equatable {
		case viewDidAppear
		case currencyLoaded(FiatCurrency)
		case isCurrencyAmountVisibleLoaded(Bool)
	}
}

public extension Home.Action {
	enum CoordinatingAction: Equatable {
		case displaySettings
		case copyAddress(Home.AccountRow.State)
	}
}
