import AccountDetailsFeature
import AccountListFeature
import AccountsClient
import AppPreferencesClient
import CreateEntityFeature
import FeaturePrelude

// MARK: - Home
public struct Home: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		// MARK: - Components
		public var header: Header.State
		public var accountList: AccountList.State
		public var accounts: IdentifiedArrayOf<Profile.Network.Account> {
			.init(uniqueElements: accountList.accounts.map(\.account))
		}

		// MARK: - Destinations
		@PresentationState
		public var destination: Destinations.State?

		public init(
			header: Header.State = .init(),
			accountList: AccountList.State = .init(accounts: []),
			destination: Destinations.State? = nil
		) {
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
		case accountsLoadedResult(TaskResult<Profile.Network.Accounts>)
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

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient

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
				for try await accounts in await accountsClient.accountsOnCurrentNetwork() {
					guard !Task.isCancelled else {
						return
					}
					await send(.internal(.accountsLoadedResult(.success(accounts))))
				}
			} catch: { error, _ in
				errorQueue.schedule(error)
			}
		case .createAccountButtonTapped:
			state.destination = .createAccount(
				.init(config: .init(
					purpose: .newAccountFromHome
				), displayIntroduction: { _ in false })
			)
			return .none
		case .pullToRefreshStarted:
			let accountAddresses = state.accounts.map(\.address)
			return .run { _ in
				_ = try await accountPortfoliosClient.fetchAccountPortfolios(accountAddresses, true)
			}
		default:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .accountsLoadedResult(.success(accounts)):
			state.accountList = .init(accounts: accounts)
			let accountAddresses = state.accounts.map(\.address)
			return .run { _ in
				_ = try await accountPortfoliosClient.fetchAccountPortfolios(accountAddresses, false)
			}

		case let .accountsLoadedResult(.failure(error)):
			errorQueue.schedule(error)
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .accountList(.delegate(.displayAccountDetails(account))):
			state.destination = .accountDetails(.init(for: account.account))
			return .none

		case .header(.delegate(.displaySettings)):
			return .run { send in
				await send(.delegate(.displaySettings))
			}

		case .destination(.presented(.accountDetails(.delegate(.dismiss)))):
			state.destination = nil
			return .none

		default:
			return .none
		}
	}
}
