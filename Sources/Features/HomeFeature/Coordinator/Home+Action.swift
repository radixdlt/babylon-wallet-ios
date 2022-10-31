import AccountDetailsFeature
import AccountListFeature
import AccountPortfolio
import AccountPreferencesFeature
import AggregatedValueFeature
import AppSettings
import Collections
import Common
import ComposableArchitecture
import CreateAccountFeature
import Foundation
import IncomingConnectionRequestFromDappReviewFeature
import NonEmpty
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

		#if DEBUG
		case debugInitiatedConnectionRequest(IncomingConnectionRequestFromDappReview.Action)
		#endif
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

		#if DEBUG
		case showDAppConnectionRequest
		#endif
	}
}

// MARK: - Home.Action.InternalAction.SystemAction
public extension Home.Action.InternalAction {
	enum SystemAction: Equatable {
		case viewDidAppear
		case loadAccountsAndSettings
		case accountsLoadedResult(TaskResult<NonEmpty<OrderedSet<OnNetwork.Account>>>)
		case appSettingsLoadedResult(TaskResult<AppSettings>)
		case toggleIsCurrencyAmountVisible
		case isCurrencyAmountVisibleLoaded(Bool)
		case fetchPortfolioResult(TaskResult<AccountPortfolioDictionary>)
		case accountPortfolioResult(TaskResult<AccountPortfolioDictionary>)
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
