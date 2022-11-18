import AccountDetailsFeature
import AccountListFeature
import AccountPortfolio
import AccountPreferencesFeature
import CreateAccountFeature
import EngineToolkit
import IdentifiedCollections
import IncomingConnectionRequestFromDappReviewFeature
import P2PConnectivityClient
import Profile
import ProfileClient
import SharedModels
import TransactionSigningFeature

// MARK: - Home.State
public extension Home {
	// MARK: State
	struct State: Equatable {
		public var accountPortfolioDictionary: AccountPortfolioDictionary

		// MARK: - Components
		public var header: Home.Header.State
		public var accountList: AccountList.State

		// MARK: - Children
		public var accountDetails: AccountDetails.State?
		public var accountPreferences: AccountPreferences.State?
		public var createAccount: CreateAccount.State?
		public var transfer: AccountDetails.Transfer.State?

		public var unfinishedRequestsFromClient: P2P.UnfinishedRequestsFromClient
		public var handleRequest: HandleRequest?

		public init(
			accountPortfolioDictionary: AccountPortfolioDictionary = [:],
			header: Home.Header.State = .init(),
			accountList: AccountList.State = .init(accounts: []),
			accountDetails: AccountDetails.State? = nil,
			accountPreferences: AccountPreferences.State? = nil,
			createAccount: CreateAccount.State? = nil,
			unfinishedRequestsFromClient: P2P.UnfinishedRequestsFromClient = .init(),
			handleRequest: HandleRequest? = nil,
			transfer: AccountDetails.Transfer.State? = nil
		) {
			self.accountPortfolioDictionary = accountPortfolioDictionary
			self.header = header
			self.accountList = accountList
			self.accountDetails = accountDetails
			self.accountPreferences = accountPreferences
			self.createAccount = createAccount
			self.unfinishedRequestsFromClient = unfinishedRequestsFromClient
			self.handleRequest = handleRequest
			self.transfer = transfer
		}
	}
}

// MARK: - Home.State.HandleRequest
public extension Home.State {
	var chooseAccountRequestFromDapp: IncomingConnectionRequestFromDappReview.State? {
		get {
			guard let handleRequest else { return nil }
			switch handleRequest {
			case let .chooseAccountRequestFromDapp(state):
				return state
			default: return nil
			}
		}
		set {
			if let newValue {
				handleRequest = .chooseAccountRequestFromDapp(newValue)
			} else {
				handleRequest = nil
			}
		}
	}

	var transactionSigning: TransactionSigning.State? {
		get {
			guard let handleRequest else { return nil }
			switch handleRequest {
			case let .transactionSigning(state):
				return state
			default: return nil
			}
		}
		set {
			if let newValue {
				handleRequest = .transactionSigning(newValue)
			} else {
				handleRequest = nil
			}
		}
	}

	enum HandleRequest: Equatable {
		case transactionSigning(TransactionSigning.State)
		case chooseAccountRequestFromDapp(IncomingConnectionRequestFromDappReview.State)
		public init(requestItemToHandle: P2P.RequestItemToHandle) {
			switch requestItemToHandle.requestItem {
			case let .oneTimeAccountAddresses(item):
				self = .chooseAccountRequestFromDapp(
					.init(request: .init(
						requestItem: item,
						parentRequest: requestItemToHandle.parentRequest
					)
					)
				)
			case let .signTransaction(item):
				self = .transactionSigning(
					.init(
						request: .init(
							requestItem: item,
							parentRequest: requestItemToHandle.parentRequest
						)
					)
				)
			}
		}
	}
}

#if DEBUG

public extension Home.State {
	static let placeholder = Home.State(
		header: .init(hasNotification: false)
	)
}
#endif
