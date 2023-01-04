import AccountDetailsFeature
import AccountListFeature
import AccountPortfolio
import AccountPreferencesFeature
import CreateAccountFeature
import EngineToolkit
import IdentifiedCollections
import Profile
import ProfileClient

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
		public var createAccountFlow: CreateAccountCoordinator.State?
		public var transfer: AccountDetails.Transfer.State?

		public init(
			accountPortfolioDictionary: AccountPortfolioDictionary = [:],
			header: Home.Header.State = .init(),
			accountList: AccountList.State = .init(accounts: []),
			accountDetails: AccountDetails.State? = nil,
			accountPreferences: AccountPreferences.State? = nil,
			createAccount: CreateAccountCoordinator.State? = nil,
			transfer: AccountDetails.Transfer.State? = nil
		) {
			self.accountPortfolioDictionary = accountPortfolioDictionary
			self.header = header
			self.accountList = accountList
			self.accountDetails = accountDetails
			self.accountPreferences = accountPreferences
			self.createAccountFlow = createAccount
			self.transfer = transfer
		}
	}
}

#if DEBUG

public extension Home.State {
	static let previewValue = Home.State(
		header: .init(hasNotification: false),
		accountDetails: AccountDetails.State(
			for: .init(
				account: .previewValue0,
				aggregatedValue: nil,
				portfolio: AccountPortfolio(
					fungibleTokenContainers: [],
					nonFungibleTokenContainers: [.mock1, .mock2, .mock3],
					poolShareContainers: [],
					badgeContainers: []
				),
				currency: .gbp,
				isCurrencyAmountVisible: false
			)
		)
	)
}
#endif
