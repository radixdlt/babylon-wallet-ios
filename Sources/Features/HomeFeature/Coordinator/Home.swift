import AccountDetailsFeature
import AccountListFeature
import AccountPortfolioFetcherClient
import AccountsClient
import AppPreferencesClient
import CreateEntityFeature
import FeaturePrelude
import FungibleTokenListFeature

// MARK: - Home
public struct Home: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var accountPortfolios: IdentifiedArrayOf<AccountPortfolio>

		// MARK: - Components
		public var header: Header.State
		public var accountList: AccountList.State
		public var accounts: IdentifiedArrayOf<OnNetwork.Account> {
			.init(uniqueElements: accountList.accounts.map(\.account))
		}

		// MARK: - Destinations
		@PresentationState
		public var destination: Destinations.State?

		public init(
			accountPortfolios: IdentifiedArrayOf<AccountPortfolio> = .init(),
			header: Header.State = .init(),
			accountList: AccountList.State = .init(accounts: []),
			destination: Destinations.State? = nil
		) {
			self.accountPortfolios = accountPortfolios
			self.header = header
			self.accountList = accountList
			self.destination = destination
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case task
		case pullToRefreshStarted
		case createAccountButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case accountsLoadedResult(TaskResult<OnNetwork.Accounts>)
		case gotAppPreferences(AppPreferences)
		case isCurrencyAmountVisibleLoaded(Bool)
		case accountPortfoliosResult(TaskResult<IdentifiedArrayOf<AccountPortfolio>>)
		case singleAccountPortfolioResult(TaskResult<AccountPortfolio>)
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

	@Dependency(\.accountPortfolioFetcherClient) var accountPortfolioFetcherClient
	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.accountsClient) var accountsClient

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
		case .task:
			return .run { send in
				do {
					for try await accounts in await accountsClient.accountsOnCurrentNetwork() {
						guard !Task.isCancelled else {
							return
						}
						await send(.internal(.accountsLoadedResult(.success(accounts))))
					}
				} catch {
					errorQueue.schedule(error)
				}
			}
		case .appeared:
			return getAppPreferences()

		case .pullToRefreshStarted:
//			return getAppPreferences().concatenate(with: fetchPortfolio(state.accountList.accounts))
			fatalError()

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

		case let .gotAppPreferences(appPreferences):
			// FIXME: Replace currency with value from Profile!
			let currency = appPreferences.display.fiatCurrencyPriceTarget
			state.accountList.accounts.forEach {
				state.accountList.accounts[id: $0.address]?.currency = currency
			}
			return .run { send in
				await send(.internal(.isCurrencyAmountVisibleLoaded(appPreferences.display.isCurrencyAmountVisible)))
			}

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

		case let .accountPortfoliosResult(.success(accountPortfolios)):
			state.accountPortfolios = accountPortfolios
			state.accountList.accounts.forEach { account in
				let address = account.address
				let accountPortfolio = accountPortfolios[id: address] ?? AccountPortfolio.empty(owner: address)
				state.accountList.accounts[id: address]?.portfolio = accountPortfolio
			}

			// account details
			if let details = state.destination?.accountDetails {
				let account = details.account
				let address = account.address

				// asset list
				let accountPortfolio = accountPortfolios[id: address] ?? AccountPortfolio.empty(owner: address)
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

		case let .accountPortfoliosResult(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case let .singleAccountPortfolioResult(.success(accountPortfolio)):
			state.accountPortfolios[id: accountPortfolio.owner] = accountPortfolio
			return .run { [accountPortfolios = state.accountPortfolios] send in
				await send(.internal(.accountPortfoliosResult(.success(accountPortfolios))))
			}

		case let .singleAccountPortfolioResult(.failure(error)):
			errorQueue.schedule(error)
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .accountList(.delegate(.fetchPortfolioForAccounts)):
			return refreshAccounts(state.accounts)

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
				await send(.internal(.singleAccountPortfolioResult(TaskResult {
					try await accountPortfolioFetcherClient.fetchPortfolioForAccount(address)
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
			return .none

		default:
			return .none
		}
	}

	private func refreshAccount(_ address: AccountAddress) -> EffectTask<Action> {
		.run { send in
			await send(.internal(.singleAccountPortfolioResult(TaskResult {
				try await accountPortfolioFetcherClient.fetchPortfolioForAccount(address)
			})))
		}
	}

	private func refreshAccounts(_ accounts: IdentifiedArrayOf<OnNetwork.Account>) -> EffectTask<Action> {
		.run { send in
			await send(.internal(.accountPortfoliosResult(TaskResult {
				try await accountPortfolioFetcherClient.fetchPortfolioFor(accounts: accounts)
			})))
		}
	}

	private func toggleCurrencyAmountVisible() -> EffectTask<Action> {
		.run { _ in
			try await appPreferencesClient.updatingDisplay {
				$0.isCurrencyAmountVisible.toggle()
			}
		}
	}

	private func getAppPreferences() -> EffectTask<Action> {
		.run { send in
			await send(.internal(.gotAppPreferences(
				appPreferencesClient.getPreferences()
			)))
		}
	}

	private func fetchPortfolio(_ accounts: some Collection<OnNetwork.Account> & Sendable) -> EffectTask<Action> {
		.run { send in
			await send(.internal(.accountPortfoliosResult(TaskResult {
				try await accountPortfolioFetcherClient.fetchPortfolioForAccounts(accounts.map(\.address))
			})))
		}
	}
}
