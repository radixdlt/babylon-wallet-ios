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

		var selectedAccounts: [ChooseAccountsRow.State] {
			availableAccounts.filter(\.isSelected)
		}

		let accessKind: AccessKind
		let dappDefinitionAddress: DappDefinitionAddress
		let dappMetadata: DappMetadata
		let numberOfAccounts: DappInteraction.NumberOfAccounts
		var availableAccounts: IdentifiedArrayOf<ChooseAccountsRow.State>

		@PresentationState
		var createAccountCoordinator: CreateAccountCoordinator.State?

		init(
			accessKind: AccessKind,
			dappDefinitionAddress: DappDefinitionAddress,
			dappMetadata: DappMetadata,
			numberOfAccounts: DappInteraction.NumberOfAccounts,
			availableAccounts: IdentifiedArrayOf<ChooseAccountsRow.State> = [],
			createAccountCoordinator: CreateAccountCoordinator.State? = nil
		) {
			self.accessKind = accessKind
			self.dappDefinitionAddress = dappDefinitionAddress
			self.dappMetadata = dappMetadata
			self.numberOfAccounts = numberOfAccounts
			self.availableAccounts = availableAccounts
			self.createAccountCoordinator = createAccountCoordinator
		}
	}

	enum ViewAction: Sendable, Equatable {
		case didAppear
		case continueButtonTapped
		case createAccountButtonTapped
	}

	enum InternalAction: Sendable, Equatable {
		case loadAccountsResult(TaskResult<OnNetwork.Accounts>)
	}

	enum ChildAction: Sendable, Equatable {
		case account(id: ChooseAccountsRow.State.ID, action: ChooseAccountsRow.Action)
		case createAccountCoordinator(PresentationActionOf<CreateAccountCoordinator>)
	}

	enum DelegateAction: Sendable, Equatable {
		case continueButtonTapped(IdentifiedArrayOf<OnNetwork.Account>, ChooseAccounts.State.AccessKind)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.accountsClient) var accountsClient

	var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.forEach(\.availableAccounts, action: /Action.child .. ChildAction.account) {
				ChooseAccountsRow()
			}
			.presentationDestination(\.$createAccountCoordinator, action: /Action.child .. ChildAction.createAccountCoordinator) {
				CreateAccountCoordinator()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .didAppear:
			return .run { send in
				await send(.internal(.loadAccountsResult(TaskResult {
					try await accountsClient.getAccountsOnCurrentNetwork()
				})))
			}

		case .continueButtonTapped:
			let selectedAccounts = IdentifiedArrayOf(uniqueElements: state.selectedAccounts.map(\.account))
			return .send(.delegate(.continueButtonTapped(selectedAccounts, state.accessKind)))

		case .createAccountButtonTapped:
			state.createAccountCoordinator = .init(config: .init(
				purpose: .newAccountDuringDappInteraction
			))
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadAccountsResult(.success(accounts)):
			let mode: ChooseAccountsRow.State.Mode = state.numberOfAccounts.quantifier == .exactly &&
				state.numberOfAccounts.quantity == 1 ? .radioButton : .checkmark

			state.availableAccounts = .init(uniqueElements: accounts.map {
				ChooseAccountsRow.State(account: $0, mode: mode)
			})
			return .none

		case let .loadAccountsResult(.failure(error)):
			errorQueue.schedule(error)
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .account(id: id, action: .delegate(.didSelect)):
			guard let account = state.availableAccounts[id: id] else { return .none }
			let numberOfAccounts = state.numberOfAccounts

			if account.isSelected {
				state.availableAccounts[id: id]?.isSelected = false
			} else {
				switch numberOfAccounts.quantifier {
				case .atLeast:
					state.availableAccounts[id: id]?.isSelected = true
				case .exactly:
					switch numberOfAccounts.quantity {
					case 1:
						state.availableAccounts.forEach {
							state.availableAccounts[id: $0.id]?.isSelected = $0.id == id
						}
					default:
						guard state.selectedAccounts.count < numberOfAccounts.quantity else { break }
						state.availableAccounts[id: id]?.isSelected = true
					}
				}
			}

			return .none

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
