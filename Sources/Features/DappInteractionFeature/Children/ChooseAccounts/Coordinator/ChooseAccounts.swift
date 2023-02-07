import CreateEntityFeature
import FeaturePrelude
import ProfileClient

// MARK: - ChooseAccounts
struct ChooseAccounts: Sendable, FeatureReducer {
	struct State: Hashable {
		enum AccessKind: Sendable, Hashable {
			case ongoing
			case oneTime
		}

		var selectedAccounts: [ChooseAccounts.Row.State] {
			availableAccounts.filter(\.isSelected)
		}

		let interactionItem: DappInteractionFlow.State.AnyInteractionItem! // TODO: @davdroman factor out onto Proxy reducer
		let accessKind: AccessKind
		let dappDefinitionAddress: DappDefinitionAddress
		let dappMetadata: DappMetadata
		let numberOfAccounts: DappInteraction.NumberOfAccounts
		var availableAccounts: IdentifiedArrayOf<ChooseAccounts.Row.State>
		var createAccountCoordinator: CreateAccountCoordinator.State?

		init(
			interactionItem: DappInteractionFlow.State.AnyInteractionItem!,
			accessKind: AccessKind,
			dappDefinitionAddress: DappDefinitionAddress,
			dappMetadata: DappMetadata,
			numberOfAccounts: DappInteraction.NumberOfAccounts,
			availableAccounts: IdentifiedArrayOf<ChooseAccounts.Row.State> = [],
			createAccountCoordinator: CreateAccountCoordinator.State? = nil
		) {
			self.interactionItem = interactionItem
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
		case loadAccountsResult(TaskResult<NonEmpty<IdentifiedArrayOf<OnNetwork.Account>>>)
	}

	enum ChildAction: Sendable, Equatable {
		case account(id: ChooseAccounts.Row.State.ID, action: ChooseAccounts.Row.Action)
		case createAccountCoordinator(CreateAccountCoordinator.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case continueButtonTapped(
			DappInteractionFlow.State.AnyInteractionItem,
			IdentifiedArrayOf<OnNetwork.Account>,
			ChooseAccounts.State.AccessKind
		)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.profileClient) var profileClient

	var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.forEach(\.availableAccounts, action: /Action.child .. ChildAction.account) {
				ChooseAccounts.Row()
			}
			.ifLet(\.createAccountCoordinator, action: /Action.child .. ChildAction.createAccountCoordinator) {
				CreateAccountCoordinator()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .didAppear:
			return .run { send in
				await send(.internal(.loadAccountsResult(TaskResult {
					try await profileClient.getAccounts()
				})))
			}

		case .continueButtonTapped:
			let selectedAccounts = IdentifiedArrayOf(uniqueElements: state.selectedAccounts.map(\.account))
			return .send(.delegate(.continueButtonTapped(state.interactionItem, selectedAccounts, state.accessKind)))

		case .createAccountButtonTapped:
			state.createAccountCoordinator = .init(config: .init(
				isFirstEntity: false,
				canBeDismissed: true,
				navigationButtonCTA: .goBackToChooseAccounts
			))
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadAccountsResult(.success(accounts)):
			state.availableAccounts = .init(uniqueElements: accounts.map {
				ChooseAccounts.Row.State(account: $0)
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
					guard state.selectedAccounts.count < numberOfAccounts.quantity else { break }
					state.availableAccounts[id: id]?.isSelected = true
				}
			}

			return .none

		case .createAccountCoordinator(.delegate(.dismissed)):
			state.createAccountCoordinator = nil
			return .none

		case .createAccountCoordinator(.delegate(.completed)):
			state.createAccountCoordinator = nil
			return .run { send in
				await send(.internal(.loadAccountsResult(TaskResult {
					try await profileClient.getAccounts()
				})))
			}

		default:
			return .none
		}
	}
}
