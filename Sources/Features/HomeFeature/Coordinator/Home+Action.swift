import AccountDetailsFeature
import AccountListFeature
import AccountPortfolio
import AccountPreferencesFeature
import AppSettings
import Common
import ComposableArchitecture
import CreateAccountFeature
import GrantDappWalletAccessFeature
import P2PConnectivityClient
import Profile
import RadixFoundation
import SharedModels
import TransactionSigningFeature

// MARK: - Home.Action
public extension Home {
	// MARK: Action
	enum Action: Sendable, Equatable {
		case child(ChildAction)
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - Home.Action.ChildAction
public extension Home.Action {
	enum ChildAction: Sendable, Equatable {
		case accountList(AccountList.Action)
		case header(Home.Header.Action)
		case accountPreferences(AccountPreferences.Action)
		case accountDetails(AccountDetails.Action)
		case transfer(AccountDetails.Transfer.Action)
		case createAccount(CreateAccount.Action)
	}
}

// MARK: - Home.Action.ViewAction
public extension Home.Action {
	enum ViewAction: Sendable, Equatable {
		case didAppear
		case pullToRefreshStarted
		case createAccountButtonTapped
	}
}

// MARK: - Home.Action.InternalAction
public extension Home.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - Home.Action.SystemAction
public extension Home.Action {
	enum SystemAction: Sendable, Equatable {
		case createAccount(numberOfExistingAccounts: Int)

		case accountsLoadedResult(TaskResult<NonEmpty<OrderedSet<OnNetwork.Account>>>)
		case appSettingsLoadedResult(TaskResult<AppSettings>)
		case isCurrencyAmountVisibleLoaded(Bool)
		case fetchPortfolioResult(TaskResult<AccountPortfolioDictionary>)
		case accountPortfolioResult(TaskResult<AccountPortfolioDictionary>)
	}
}

// MARK: - Home.Action.DelegateAction
public extension Home.Action {
	enum DelegateAction: Sendable, Equatable {
		case displaySettings
		case reloadAccounts
	}
}
