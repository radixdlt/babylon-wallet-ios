import AccountDetailsFeature
import AccountListFeature
import AccountPortfolio
import AccountPreferencesFeature
import AggregatedValueFeature
import AppSettings
import BrowserExtensionsConnectivityClient
import Collections
import Common
import ComposableArchitecture
import CreateAccountFeature
import Foundation
import IncomingConnectionRequestFromDappReviewFeature
import NonEmpty
import Profile
import TransactionSigningFeature

// MARK: - Home.Action
public extension Home {
	// MARK: Action
	enum Action: Equatable {
		case child(ChildAction)
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - Home.Action.ChildAction
public extension Home.Action {
	enum ChildAction: Equatable {
		case accountList(AccountList.Action)
		case aggregatedValue(AggregatedValue.Action)
		case header(Home.Header.Action)
		case visitHub(Home.VisitHub.Action)
		case accountPreferences(AccountPreferences.Action)
		case accountDetails(AccountDetails.Action)
		case transfer(AccountDetails.Transfer.Action)
		case createAccount(CreateAccount.Action)
		case chooseAccountRequestFromDapp(IncomingConnectionRequestFromDappReview.Action)
		case transactionSigning(TransactionSigning.Action)
	}
}

// MARK: - Home.Action.ViewAction
public extension Home.Action {
	enum ViewAction: Equatable {
		case didAppear
		case createAccountButtonTapped
	}
}

// MARK: - Home.Action.InternalAction
public extension Home.Action {
	enum InternalAction: Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - Home.Action.SystemAction
public extension Home.Action {
	enum SystemAction: Equatable {
		case createAccount(numberOfExistingAccounts: Int)

		case subscribeToIncomingMessagesFromDappsByBrowserConnectionIDs(OrderedSet<BrowserExtensionConnection.ID>)

		case receiveRequestMessageFromDappResult(TaskResult<IncomingMessageFromBrowser>)
		case presentViewForRequestFromBrowser(IncomingMessageFromBrowser)
		case presentViewForNextBufferedRequestFromBrowserIfNeeded

		case accountsLoadedResult(TaskResult<NonEmpty<OrderedSet<OnNetwork.Account>>>)
		case appSettingsLoadedResult(TaskResult<AppSettings>)
		case connectionsLoadedResult(TaskResult<[BrowserExtensionWithConnectionStatus]>)
		case toggleIsCurrencyAmountVisible
		case isCurrencyAmountVisibleLoaded(Bool)
		case fetchPortfolioResult(TaskResult<AccountPortfolioDictionary>)
		case accountPortfolioResult(TaskResult<AccountPortfolioDictionary>)
		case viewDidAppearActionFailed(reason: String)
		case toggleIsCurrencyAmountVisibleFailed(reason: String)
		case sendResponseBackToDapp(BrowserExtensionConnection.ID, RequestMethodWalletResponse)
		case sendResponseBackToDappResult(TaskResult<SentMessageToBrowser>)
	}
}

// MARK: - Home.Action.DelegateAction
public extension Home.Action {
	enum DelegateAction: Equatable {
		case displaySettings
	}
}
