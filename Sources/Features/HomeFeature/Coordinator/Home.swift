import AccountDetailsFeature
import AccountListFeature
import AccountPortfolio
import AccountPreferencesFeature
import AppSettings
import CreateEntityFeature
import FeaturePrelude
import FungibleTokenListFeature
import P2PConnectivityClient
import ProfileClient
import TransactionSigningFeature

// MARK: - Home
public struct Home: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var accountPortfolioDictionary: AccountPortfolioDictionary

		// MARK: - Components
		public var header: Home.Header.State
		public var accountList: AccountList.State

		// MARK: - Children
		public var accountDetails: AccountDetails.State?
		public var accountPreferences: AccountPreferences.State?
		public var createAccountCoordinator: CreateAccountCoordinator.State?

		public init(
			accountPortfolioDictionary: AccountPortfolioDictionary = [:],
			header: Home.Header.State = .init(),
			accountList: AccountList.State = .init(accounts: []),
			accountDetails: AccountDetails.State? = nil,
			accountPreferences: AccountPreferences.State? = nil,
			createAccount: CreateAccountCoordinator.State? = nil
		) {
			self.accountPortfolioDictionary = accountPortfolioDictionary
			self.header = header
			self.accountList = accountList
			self.accountDetails = accountDetails
			self.accountPreferences = accountPreferences
			self.createAccountCoordinator = createAccount
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case pullToRefreshStarted
		case createAccountButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case accountsLoadedResult(TaskResult<NonEmpty<IdentifiedArrayOf<OnNetwork.Account>>>)
		case appSettingsLoadedResult(TaskResult<AppSettings>)
		case isCurrencyAmountVisibleLoaded(Bool)
		case fetchPortfolioResult(TaskResult<AccountPortfolioDictionary>)
		case accountPortfolioResult(TaskResult<AccountPortfolioDictionary>)
	}

	public enum ChildAction: Sendable, Equatable {
		case accountList(AccountList.Action)
		case header(Home.Header.Action)
		case accountPreferences(AccountPreferences.Action)
		case accountDetails(AccountDetails.Action)
		case createAccountCoordinator(CreateAccountCoordinator.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case displaySettings
		case reloadAccounts
	}

	@Dependency(\.accountPortfolioFetcher) var accountPortfolioFetcher
	@Dependency(\.appSettingsClient) var appSettingsClient
	@Dependency(\.p2pConnectivityClient) var p2pConnectivityClient
	@Dependency(\.mainQueue) var mainQueue
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.openURL) var openURL
	@Dependency(\.profileClient) var profileClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.header, action: /Action.child .. ChildAction.header) {
			Home.Header()
		}

		accountListReducer()

		Reduce(self.core)
	}

	func accountListReducer() -> some ReducerProtocolOf<Self> {
		Scope(state: \.accountList, action: /Action.child .. ChildAction.accountList) {
			AccountList()
		}
		.ifLet(\.accountDetails, action: /Action.child .. ChildAction.accountDetails) {
			AccountDetails()
		}
		.ifLet(\.accountPreferences, action: /Action.child .. ChildAction.accountPreferences) {
			AccountPreferences()
		}
		.ifLet(\.createAccountCoordinator, action: /Action.child .. ChildAction.createAccountCoordinator) {
			CreateAccountCoordinator()
		}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return loadAccountsAndSettings()

		case .pullToRefreshStarted:
			return loadAccountsAndSettings()

		case .createAccountButtonTapped:
			state.createAccountCoordinator = .init(config: .init(
				isFirstEntity: false,
				canBeDismissed: true,
				navigationButtonCTA: .goHome
			))
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .accountsLoadedResult(.success(accounts)):
			state.accountList = .init(accounts: accounts)
			return fetchPortfolio(accounts)

		case let .accountsLoadedResult(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case let .appSettingsLoadedResult(.success(appSettings)):
			// FIXME: Replace currency with value from Profile!
			let currency = appSettings.currency
			state.accountList.accounts.forEach {
				state.accountList.accounts[id: $0.address]?.currency = currency
			}
			return .run { send in
				await send(.internal(.isCurrencyAmountVisibleLoaded(appSettings.isCurrencyAmountVisible)))
			}

		case let .appSettingsLoadedResult(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case let .isCurrencyAmountVisibleLoaded(isVisible):
			// account list
			state.accountList.accounts.forEach {
				// TODO: replace hardcoded true value with isVisible value
				state.accountList.accounts[id: $0.address]?.isCurrencyAmountVisible = true
			}

			// account details
			state.accountDetails?.assets.fungibleTokenList.sections.forEach { section in
				section.assets.forEach { row in
					state.accountDetails?.assets.fungibleTokenList.sections[id: section.id]?.assets[id: row.id]?.isCurrencyAmountVisible = isVisible
				}
			}

			return .none

		case let .fetchPortfolioResult(.success(totalPortfolio)):
			state.accountPortfolioDictionary = totalPortfolio
			state.accountList.accounts.forEach {
				let accountPortfolio = totalPortfolio[$0.address] ?? AccountPortfolio.empty
				state.accountList.accounts[id: $0.address]?.portfolio = accountPortfolio
			}

			// account details
			if let details = state.accountDetails {
				let account = details.account

				// asset list
				let accountPortfolio = totalPortfolio[account.address] ?? AccountPortfolio.empty
				let categories = accountPortfolio.fungibleTokenContainers.elements.sortedIntoCategories()

				state.accountDetails?.assets = .init(
					type: details.assets.type,
					fungibleTokenList: .init(
						sections: .init(uniqueElements: categories.map { category in
							let rows = category.tokenContainers.map { container in FungibleTokenList.Row.State(container: container, currency: .usd, isCurrencyAmountVisible: true) }
							return FungibleTokenList.Section.State(id: category.type, assets: .init(uniqueElements: rows))
						})
					),
					nonFungibleTokenList: .init(
						rows: .init(uniqueElements: accountPortfolio.nonFungibleTokenContainers.elements.map {
							.init(container: $0)
						})
					)
				)
			}

			return .none

		case let .fetchPortfolioResult(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case let .accountPortfolioResult(.success(accountPortfolio)):
			guard let key = accountPortfolio.first?.key else { return .none }
			state.accountPortfolioDictionary[key] = accountPortfolio.first?.value
			return .run { [portfolio = state.accountPortfolioDictionary] send in
				await send(.internal(.fetchPortfolioResult(.success(portfolio))))
			}

		case let .accountPortfolioResult(.failure(error)):
			errorQueue.schedule(error)
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .accountList(.delegate(.fetchPortfolioForAccounts)):
			return loadAccountsAndSettings()

		case let .accountList(.delegate(.displayAccountDetails(account))):
			state.accountDetails = .init(for: account)
			return .none

		case .header(.delegate(.displaySettings)):
			return .run { send in
				await send(.delegate(.displaySettings))
			}

		case .accountPreferences(.delegate(.dismissAccountPreferences)):
			state.accountPreferences = nil
			return .none

		case let .accountPreferences(.delegate(.refreshAccount(address))):
			return .run { send in
				await send(.internal(.accountPortfolioResult(TaskResult {
					try await accountPortfolioFetcher.fetchPortfolio([address])
				})))
				await send(.child(.accountPreferences(.internal(.system(.refreshAccountCompleted)))))
			}

		case .accountDetails(.delegate(.dismissAccountDetails)):
			state.accountDetails = nil
			return .none

		case let .accountDetails(.delegate(.displayAccountPreferences(address))):
			state.accountPreferences = .init(address: address)
			return .none

		case let .accountDetails(.delegate(.refresh(address))):
			return refreshAccount(address)

		case .createAccountCoordinator(.delegate(.dismissed)):
			state.createAccountCoordinator = nil
			return .none

		case .createAccountCoordinator(.delegate(.completed)):
			state.createAccountCoordinator = nil
			return loadAccountsAndSettings()

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, action: ActionOf<Home>) -> EffectTask<ActionOf<Home>> {
		switch action {
		case let .delegate(delegateAction):
			switch delegateAction {
			case .displaySettings:
				return .none

			case .reloadAccounts:
				return loadAccountsAndSettings()
			}

		default:
			return .none
		}
	}

	private func refreshAccount(_ address: AccountAddress) -> EffectTask<Action> {
		.run { send in
			await send(.internal(.accountPortfolioResult(TaskResult {
				try await accountPortfolioFetcher.fetchPortfolio([address])
			})))
		}
	}

	private func toggleCurrencyAmountVisible() -> EffectTask<Action> {
		.run { send in
			var isVisible = try await appSettingsClient.loadSettings().isCurrencyAmountVisible
			isVisible.toggle()
			try await appSettingsClient.saveIsCurrencyAmountVisible(isVisible)
			await send(.internal(.isCurrencyAmountVisibleLoaded(isVisible)))
		}
	}

	private func loadAccountsAndSettings() -> EffectTask<Action> {
		.run { send in
			await send(.internal(.accountsLoadedResult(
				TaskResult {
					try await profileClient.getAccounts()
				}
			)))
			await send(.internal(.appSettingsLoadedResult(
				TaskResult {
					try await appSettingsClient.loadSettings()
				}
			)))
		}
	}

	private func fetchPortfolio(_ accounts: some Collection<OnNetwork.Account> & Sendable) -> EffectTask<Action> {
		.run { send in
			await send(.internal(.fetchPortfolioResult(TaskResult {
				try await accountPortfolioFetcher.fetchPortfolio(accounts.map(\.address))
			})))
		}
	}
}
