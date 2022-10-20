import AccountDetailsFeature
import AccountListFeature
import AccountPortfolio
import AccountPreferencesFeature
import AggregatedValueFeature
import Common
import CreateAccountFeature
import Foundation
import Profile

// MARK: - Home.Action
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

// MARK: - Home.Action.InternalAction
public extension Home.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
		case coordinate(InternalCoordinateAction)
	}
}

// MARK: - Home.Action.InternalAction.UserAction
public extension Home.Action.InternalAction {
	enum UserAction: Equatable {
		case createAccountButtonTapped
	}
}

// MARK: - Home.Action.InternalAction.SystemAction
public extension Home.Action.InternalAction {
	enum SystemAction: Equatable {
		case viewDidAppear
		case currencyLoaded(FiatCurrency)
		case toggleIsCurrencyAmountVisible
		case isCurrencyAmountVisibleLoaded(Bool)
		case totalPortfolioLoaded(AccountPortfolioDictionary)
		case accountPortfolioLoaded(AccountPortfolioDictionary)
		case copyAddress(Address)
		case viewDidAppearActionFailed(reason: String)
		case toggleIsCurrencyAmountVisibleFailed(reason: String)
	}

	enum InternalCoordinateAction: Equatable {
		case createAccount(numberOfExistingAccounts: Int)
	}
}

// MARK: - Home.Action.CoordinatingAction
public extension Home.Action {
	enum CoordinatingAction: Equatable {
		case displaySettings
	}
}
