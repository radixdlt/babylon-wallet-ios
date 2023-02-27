import AccountDetailsFeature
import AccountListFeature
import AccountPortfolio
import AppSettings
import CreateEntityFeature
import FeaturePrelude
import FungibleTokenListFeature
import ProfileClient

// MARK: - Home
public struct Home: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var accountPortfolioDictionary: AccountPortfolioDictionary

		// MARK: - Components
		public var header: Header.State
		public var accountList: AccountList.State

		// MARK: - Destinations
		@PresentationState
		public var destination: Destinations.State?

		public init(
			accountPortfolioDictionary: AccountPortfolioDictionary = [:],
			header: Header.State = .init(),
			accountList: AccountList.State = .init(accounts: []),
			destination: Destinations.State? = nil
		) {
			self.accountPortfolioDictionary = accountPortfolioDictionary
			self.header = header
			self.accountList = accountList
			self.destination = destination
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case pullToRefreshStarted
		case createAccountButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case accountsLoadedResult(TaskResult<OnNetwork.Accounts>)
		case appSettingsLoadedResult(TaskResult<AppSettings>)
		case isCurrencyAmountVisibleLoaded(Bool)
		case fetchPortfolioResult(TaskResult<AccountPortfolioDictionary>)
		case accountPortfolioResult(TaskResult<AccountPortfolioDictionary>)
	}

	public enum ChildAction: Sendable, Equatable {
		case header(Header.Action)
		case accountList(AccountList.Action)
		case destination(PresentationAction<Destinations.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case displaySettings
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case accountDetails(AccountDetails.State)
			case createAccount(CreateAccountCoordinator.State)

			// NB: native case paths should deem this obsolete.
			// e.g. `state.destination?[keyPath: \.accountDetails] = ...` or even conciser via `@dynamicMemberLookup`
			var accountDetails: AccountDetails.State? {
				get {
					guard case let .accountDetails(state) = self else { return nil }
					return state
				}
				set {
					guard case .accountDetails = self, let state = newValue else { return }
					self = .accountDetails(state)
				}
			}
		}

		public enum Action: Sendable, Equatable {
			case accountDetails(AccountDetails.Action)
			case createAccount(CreateAccountCoordinator.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.accountDetails, action: /Action.accountDetails) {
				AccountDetails()
			}
			Scope(state: /State.createAccount, action: /Action.createAccount) {
				CreateAccountCoordinator()
			}
		}
	}

	@Dependency(\.accountPortfolioFetcher) var accountPortfolioFetcher
	@Dependency(\.appSettingsClient) var appSettingsClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.profileClient) var profileClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.header, action: /Action.child .. ChildAction.header) {
			Header()
		}

		Scope(state: \.accountList, action: /Action.child .. ChildAction.accountList) {
			AccountList()
		}

		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return loadAccountsAndSettings()

		case .pullToRefreshStarted:
			return loadAccountsAndSettings()

		case .createAccountButtonTapped:
			state.destination = .createAccount(
				.init(config: .init(
					isFirstEntity: false,
					canBeDismissed: true,
					navigationButtonCTA: .goHome
				))
			)
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
			state.destination?.accountDetails?.assets.fungibleTokenList.sections.forEach { section in
				section.assets.forEach { row in
					state.destination?.accountDetails?.assets.fungibleTokenList.sections[id: section.id]?.assets[id: row.id]?.isCurrencyAmountVisible = isVisible
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
			if let details = state.destination?.accountDetails {
				let account = details.account

				// asset list
				let accountPortfolio = totalPortfolio[account.address] ?? AccountPortfolio.empty
				let categories = accountPortfolio.fungibleTokenContainers.elements.sortedIntoCategories()

				state.destination?.accountDetails?.assets = .init(
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
			state.destination = .accountDetails(.init(for: account))
			return .none

		case .header(.delegate(.displaySettings)):
			return .run { send in
				await send(.delegate(.displaySettings))
			}

		// this whole case is just plain awful, but hopefully only temporary until we introduce account streams.
		case let .destination(.presented(.accountDetails(.child(.destination(.presented(.preferences(.delegate(.refreshAccount(address))))))))):
			return .run { send in
				await send(.internal(.accountPortfolioResult(TaskResult {
					try await accountPortfolioFetcher.fetchPortfolio([address])
				})))
				await send(.child(.destination(.presented(.accountDetails(.child(.destination(.presented(.preferences(.internal(.system(.refreshAccountCompleted)))))))))))
			}

		case .destination(.presented(.accountDetails(.delegate(.dismiss)))):
			state.destination = nil
			return .none

		case let .destination(.presented(.accountDetails(.delegate(.refresh(address))))):
			return refreshAccount(address)

		case .destination(.presented(.createAccount(.delegate(.dismissed)))):
			state.destination = nil
			return .none

		case .destination(.presented(.createAccount(.delegate(.completed)))):
			state.destination = nil
			return loadAccountsAndSettings()

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
