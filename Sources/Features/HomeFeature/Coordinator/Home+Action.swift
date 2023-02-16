/*
import AccountDetailsFeature
import AccountListFeature
import AccountPortfolio
import AccountPreferencesFeature
import AppSettings
import CreateEntityFeature
import FeaturePrelude
import P2PConnectivityClient
import TransactionSigningFeature

// MARK: - Home.Action
extension Home {
	// MARK: Action
	public enum Action: Sendable, Equatable {
		case child(ChildAction)
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - Home.Action.ChildAction
extension Home.Action {
	public enum ChildAction: Sendable, Equatable {
		case accountList(AccountList.Action)
		case header(Home.Header.Action)
		case accountPreferences(AccountPreferences.Action)
		case accountDetails(AccountDetails.Action)
		case createAccountCoordinator(CreateAccountCoordinator.Action)
	}
}

// MARK: - Home.Action.ViewAction
extension Home.Action {
	public enum ViewAction: Sendable, Equatable {
		case didAppear
		case pullToRefreshStarted
		case createAccountButtonTapped
	}
}

// MARK: - Home.Action.InternalAction
extension Home.Action {
	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - Home.Action.SystemAction
extension Home.Action {
	public enum SystemAction: Sendable, Equatable {
		case accountsLoadedResult(TaskResult<NonEmpty<IdentifiedArrayOf<OnNetwork.Account>>>)
		case appSettingsLoadedResult(TaskResult<AppSettings>)
		case isCurrencyAmountVisibleLoaded(Bool)
		case fetchPortfolioResult(TaskResult<AccountPortfolioDictionary>)
		case accountPortfolioResult(TaskResult<AccountPortfolioDictionary>)
	}
}

// MARK: - Home.Action.DelegateAction
extension Home.Action {
	public enum DelegateAction: Sendable, Equatable {
		case displaySettings
		case reloadAccounts
	}
}
*/
