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

		case chooseAccountRequestFromDapp(IncomingConnectionRequestFromDappReview.Action)
		case transactionSigning(TransactionSigning.Action)
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
		case subscribeToIncomingMessagesFromDappsByBrowserConnectionIDs(OrderedSet<BrowserExtensionConnection.ID>)

		case receiveRequestMessageFromDappResult(TaskResult<IncomingMessageFromBrowser>)
		case presentViewForRequestFromBrowser(IncomingMessageFromBrowser)
		case presentViewForNextBufferedRequestFromBrowserIfNeeded

		case loadAccountsConnectionsAndSettings
		case accountsLoadedResult(TaskResult<NonEmpty<OrderedSet<OnNetwork.Account>>>)
		case appSettingsLoadedResult(TaskResult<AppSettings>)
		case connectionsLoadedResult(TaskResult<[BrowserExtensionWithConnectionStatus]>)
		case toggleIsCurrencyAmountVisible
		case isCurrencyAmountVisibleLoaded(Bool)
		case fetchPortfolioResult(TaskResult<AccountPortfolioDictionary>)
		case accountPortfolioResult(TaskResult<AccountPortfolioDictionary>)
		case copyAddress(Address)
		case viewDidAppearActionFailed(reason: String)
		case toggleIsCurrencyAmountVisibleFailed(reason: String)
		case sendResponseBackToDapp(BrowserExtensionConnection.ID, RequestMethodWalletResponse)
		case sendResponseBackToDappResult(TaskResult<SentMessageToBrowser>)
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
