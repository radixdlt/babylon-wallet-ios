import AccountDetailsFeature
import AccountListFeature
import AccountPortfolio
import AccountPreferencesFeature
import AggregatedValueFeature
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
		public var aggregatedValue: AggregatedValue.State
		public var accountList: AccountList.State
		public var visitHub: Home.VisitHub.State

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
			aggregatedValue: AggregatedValue.State = .init(),
			accountList: AccountList.State = .init(accounts: []),
			visitHub: Home.VisitHub.State = .init(),
			accountDetails: AccountDetails.State? = nil,
			accountPreferences: AccountPreferences.State? = nil,
			createAccount: CreateAccount.State? = nil,
			unfinishedRequestsFromClient: P2P.UnfinishedRequestsFromClient = .init(),
			handleRequest: HandleRequest? = nil,
			transfer: AccountDetails.Transfer.State? = nil
		) {
			self.accountPortfolioDictionary = accountPortfolioDictionary
			self.header = header
			self.aggregatedValue = aggregatedValue
			self.accountList = accountList
			self.visitHub = visitHub
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
				//                self = .transactionSigning(.init(requestFromClient: <#T##P2P.RequestFromClient#>, addressOfSigner: <#T##AccountAddress#>, transactionManifest: <#T##TransactionManifest#>))
				fatalError()
			}
		}
	}
}

#if DEBUG

public extension Home.State {
	static let placeholder = Home.State(
		header: .init(hasNotification: false),
		aggregatedValue: .placeholder,
		visitHub: .init()
	)
}
#endif
