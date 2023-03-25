import AccountsClient
import CreateEntityFeature
import FeaturePrelude

// MARK: - ChooseAccounts
struct ChooseAccounts: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		enum AccessKind: Sendable, Hashable {
			case ongoing
			case oneTime
		}

		let accessKind: AccessKind
		let dappDefinitionAddress: DappDefinitionAddress
		let dappMetadata: DappMetadata
		let numberOfAccounts: DappInteraction.NumberOfAccounts
		var availableAccounts: IdentifiedArrayOf<Profile.Network.Account>
		var selectedAccounts: [ChooseAccountsRow.State]?

		@PresentationState
		var createAccountCoordinator: CreateAccountCoordinator.State?

		init(
			accessKind: AccessKind,
			dappDefinitionAddress: DappDefinitionAddress,
			dappMetadata: DappMetadata,
			numberOfAccounts: DappInteraction.NumberOfAccounts,
			availableAccounts: IdentifiedArrayOf<Profile.Network.Account> = [],
			selectedAccounts: [ChooseAccountsRow.State]? = nil,
			createAccountCoordinator: CreateAccountCoordinator.State? = nil
		) {
			self.accessKind = accessKind
			self.dappDefinitionAddress = dappDefinitionAddress
			self.dappMetadata = dappMetadata
			self.numberOfAccounts = numberOfAccounts
			self.availableAccounts = availableAccounts
			self.selectedAccounts = selectedAccounts
			self.createAccountCoordinator = createAccountCoordinator
		}
	}

	enum ViewAction: Sendable, Equatable {
		case appeared
		case createAccountButtonTapped
		case selectedAccountsChanged([ChooseAccountsRow.State]?)
		case continueButtonTapped([ChooseAccountsRow.State])
	}

	enum InternalAction: Sendable, Equatable {
		case loadAccountsResult(TaskResult<Profile.Network.Accounts>)
	}

	enum ChildAction: Sendable, Equatable {
		case createAccountCoordinator(PresentationAction<CreateAccountCoordinator.Action>)
	}

	enum DelegateAction: Sendable, Equatable {
		case continueButtonTapped(IdentifiedArrayOf<Profile.Network.Account>, ChooseAccounts.State.AccessKind)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.accountsClient) var accountsClient

	var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$createAccountCoordinator, action: /Action.child .. ChildAction.createAccountCoordinator) {
				CreateAccountCoordinator()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .run { send in
				await send(.internal(.loadAccountsResult(TaskResult {
					try await accountsClient.getAccountsOnCurrentNetwork()
				})))
			}

		case .createAccountButtonTapped:
			state.createAccountCoordinator = .init(config: .init(
				purpose: .newAccountDuringDappInteraction
			))
			return .none

		case let .selectedAccountsChanged(selectedAccounts):
			state.selectedAccounts = selectedAccounts
			return .none

		case let .continueButtonTapped(selectedAccounts):
			let selectedAccounts = IdentifiedArray(uncheckedUniqueElements: selectedAccounts.map(\.account))
			return .send(.delegate(.continueButtonTapped(selectedAccounts, state.accessKind)))
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadAccountsResult(.success(accounts)):
			state.availableAccounts = .init(uniqueElements: accounts)
			return .none

		case let .loadAccountsResult(.failure(error)):
			errorQueue.schedule(error)
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .createAccountCoordinator(.presented(.delegate(.dismiss))):
			state.createAccountCoordinator = nil
			return .none

		case .createAccountCoordinator(.presented(.delegate(.completed))):
			state.createAccountCoordinator = nil
			return .run { send in
				await send(.internal(.loadAccountsResult(TaskResult {
					try await accountsClient.getAccountsOnCurrentNetwork()
				})))
			}

		default:
			return .none
		}
	}
}
