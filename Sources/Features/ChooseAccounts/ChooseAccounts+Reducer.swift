import AccountsClient
import CreateAccountFeature
import EngineKit
import FeaturePrelude

// MARK: - _ChooseAccounts
public struct ChooseAccounts: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let selectionRequirement: SelectionRequirement
		public let filteredAccounts: [AccountAddress]
		public var availableAccounts: IdentifiedArrayOf<Profile.Network.Account>
		public var selectedAccounts: [ChooseAccountsRow.State]?
		public var canCreateNewAccount: Bool

		@PresentationState
		var destination: Destinations.State? = nil

		public init(
			selectionRequirement: SelectionRequirement,
			filteredAccounts: [AccountAddress] = [],
			availableAccounts: IdentifiedArrayOf<Profile.Network.Account> = [],
			selectedAccounts: [ChooseAccountsRow.State]? = nil,
			canCreateNewAccount: Bool = true
		) {
			self.selectionRequirement = selectionRequirement
			self.filteredAccounts = filteredAccounts
			self.availableAccounts = availableAccounts
			self.selectedAccounts = selectedAccounts
			self.canCreateNewAccount = canCreateNewAccount
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case createAccountButtonTapped
		case selectedAccountsChanged([ChooseAccountsRow.State]?)
	}

	public enum InternalAction: Sendable, Equatable {
		case loadAccountsResult(TaskResult<Profile.Network.Accounts>)
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public struct Destinations: Sendable, Reducer {
		public enum State: Sendable, Hashable {
			case createAccount(CreateAccountCoordinator.State)
		}

		public enum Action: Sendable, Equatable {
			case createAccount(CreateAccountCoordinator.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.createAccount, action: /Action.createAccount) {
				CreateAccountCoordinator()
			}
		}
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.accountsClient) var accountsClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return loadAccounts()

		case .createAccountButtonTapped:
			state.destination = .createAccount(.init(
				config: .init(purpose: .newAccountDuringDappInteraction)
			))
			return .none

		case let .selectedAccountsChanged(selectedAccounts):
			state.selectedAccounts = selectedAccounts
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadAccountsResult(.success(accounts)):
			// Uniqueness is guaranteed as per `Profile.Network.Accounts`
			state.availableAccounts = .init(uniqueElements: accounts).filter {
				!state.filteredAccounts.contains($0.address)
			}
			return .none

		case let .loadAccountsResult(.failure(error)):
			errorQueue.schedule(error)
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .destination(.presented(.createAccount(.delegate(.completed)))):
			return loadAccounts()

		default:
			return .none
		}
	}

	private func loadAccounts() -> EffectTask<Action> {
		.run { send in
			let result = await TaskResult {
				try await accountsClient.getAccountsOnCurrentNetwork()
			}
			await send(.internal(.loadAccountsResult(result)))
		}
	}
}
