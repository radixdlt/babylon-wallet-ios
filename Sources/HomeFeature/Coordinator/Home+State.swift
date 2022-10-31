import AccountDetailsFeature
import AccountListFeature
import AccountPortfolio
import AccountPreferencesFeature
import AggregatedValueFeature
import CreateAccountFeature
import EngineToolkit
import IncomingConnectionRequestFromDappReviewFeature
import Profile
import ProfileClient

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

		#if DEBUG
		public var debugInitiatedConnectionRequest: IncomingConnectionRequestFromDappReview.State?
		#endif

		public init(
			accountPortfolioDictionary: AccountPortfolioDictionary = [:],
			header: Home.Header.State = .init(),
			aggregatedValue: AggregatedValue.State = .init(),
			accountList: AccountList.State = .init(accounts: []),
			visitHub: Home.VisitHub.State = .init(),
			accountDetails: AccountDetails.State? = nil,
			accountPreferences: AccountPreferences.State? = nil,
			createAccount: CreateAccount.State? = nil,
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
			self.transfer = transfer
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
