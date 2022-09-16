import AccountDetailsFeature
import AccountListFeature
import AccountPreferencesFeature
import Address
import AggregatedValueFeature
import Common
import CreateAccountFeature
import Foundation

public extension Home {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)

		case accountList(AccountList.Action)
		case aggregatedValue(AggregatedValue.Action)
		case header(Home.Header.Action)
		case visitHub(Home.VisitHub.Action)
		case accountPreferences(AccountPreferences.Action)
		case accountDetails(AccountDetails.Action)
		case transfer(AccountDetails.Transfer.Action)
		case createAccount(CreateAccount.Action)
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
		case toggleIsCurrencyAmountVisible
		case isCurrencyAmountVisibleLoaded(Bool)
		case totalWorthLoaded(AccountsWorthDictionary)
		case accountWorthLoaded(AccountsWorthDictionary)
		case copyAddress(Address)
		case viewDidAppearActionFailed(reason: String)
		case toggleIsCurrencyAmountVisibleFailed(reason: String)
	}
}

public extension Home.Action {
	enum CoordinatingAction: Equatable {
		case displaySettings
	}
}
