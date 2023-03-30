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
		var availableAccounts: IdentifiedArrayOf<Profile.Network.Account>
		let numberOfAccounts: DappInteraction.NumberOfAccounts
		var selectedAccounts: [ChooseAccountsRow.State]?

		@PresentationState
		var createAccountCoordinator: CreateAccountCoordinator.State?

		init(
			accessKind: AccessKind,
			dappDefinitionAddress: DappDefinitionAddress,
			dappMetadata: DappMetadata,
			availableAccounts: IdentifiedArrayOf<Profile.Network.Account> = [],
			numberOfAccounts: DappInteraction.NumberOfAccounts,
			selectedAccounts: [ChooseAccountsRow.State]? = nil,
			createAccountCoordinator: CreateAccountCoordinator.State? = nil
		) {
			self.accessKind = accessKind
			self.dappDefinitionAddress = dappDefinitionAddress
			self.dappMetadata = dappMetadata
			self.availableAccounts = availableAccounts
			self.numberOfAccounts = numberOfAccounts
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
			), displayIntroduction: { _ in false })
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
		case .createAccountCoordinator(.presented(.delegate(.completed))):
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
