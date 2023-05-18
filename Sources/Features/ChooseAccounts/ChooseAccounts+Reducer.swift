import AccountsClient
import CreateEntityFeature
import FeaturePrelude

// MARK: - _ChooseAccounts
public struct ChooseAccounts: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let selectionRequirement: SelectionRequirement
		public var availableAccounts: IdentifiedArrayOf<Profile.Network.Account>
		public var selectedAccounts: [ChooseAccountsRow.State]?
		@PresentationState
		var destination: Destinations.State? = nil

		public init(
			selectionRequirement: SelectionRequirement,
			availableAccounts: IdentifiedArrayOf<Profile.Network.Account> = [],
			selectedAccounts: [ChooseAccountsRow.State]? = nil
		) {
			self.selectionRequirement = selectionRequirement
			self.availableAccounts = availableAccounts
			self.selectedAccounts = selectedAccounts
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

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case createAccount(CreateAccountCoordinator.State)
		}

		public enum Action: Sendable, Equatable {
			case createAccount(CreateAccountCoordinator.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.createAccount, action: /Action.createAccount) {
				CreateAccountCoordinator()
			}
		}
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.accountsClient) var accountsClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
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
				config: .init(purpose: .newAccountDuringDappInteraction),
				displayIntroduction: { _ in false }
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
			state.availableAccounts = .init(uniqueElements: accounts)
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
		.task {
			let result = await TaskResult {
				try await accountsClient.getAccountsOnCurrentNetwork()
			}
			return .internal(.loadAccountsResult(result))
		}
	}
}
