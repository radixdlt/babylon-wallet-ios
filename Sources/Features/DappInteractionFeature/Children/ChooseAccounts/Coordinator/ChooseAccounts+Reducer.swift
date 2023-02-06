import CreateEntityFeature
import FeaturePrelude
import ProfileClient

// MARK: - ChooseAccounts
struct ChooseAccounts: Sendable, ReducerProtocol {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.profileClient) var profileClient

	var body: some ReducerProtocolOf<Self> {
		Reduce { state, action in
			switch action {
			case .internal(.view(.continueButtonTapped)):
				let selectedAccounts = IdentifiedArrayOf(uniqueElements: state.selectedAccounts.map(\.account))
				return .send(.delegate(.continueButtonTapped(state.interactionItem, selectedAccounts, state.accessKind)))

			case .internal(.view(.didAppear)):
				return .run { send in
					await send(.internal(.system(.loadAccountsResult(TaskResult {
						try await profileClient.getAccounts()
					}))))
				}

			case let .internal(.system(.loadAccountsResult(.success(accounts)))):
				state.availableAccounts = .init(uniqueElements: accounts.map {
					ChooseAccounts.Row.State(account: $0)
				})
				return .none

			case let .internal(.system(.loadAccountsResult(.failure(error)))):
				errorQueue.schedule(error)
				return .none

			case .internal(.view(.createAccountButtonTapped)):
				state.createAccountCoordinator = .init(config: .init(
					isFirstEntity: false,
					canBeDismissed: true,
					navigationButtonCTA: .goBackToChooseAccounts
				))
				return .none

			case let .child(.account(id: id, action: .delegate(.didSelect))):
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

			case .child(.createAccountCoordinator(.delegate(.dismissed))):
				state.createAccountCoordinator = nil
				return .none

			case .child(.createAccountCoordinator(.delegate(.completed))):
				state.createAccountCoordinator = nil
				return .run { send in
					await send(.internal(.system(.loadAccountsResult(TaskResult {
						try await profileClient.getAccounts()
					}))))
				}

			case .child, .delegate:
				return .none
			}
		}
		.forEach(\.availableAccounts, action: /Action.child .. Action.ChildAction.account) {
			ChooseAccounts.Row()
		}
		.ifLet(\.createAccountCoordinator, action: /Action.child .. Action.ChildAction.createAccountCoordinator) {
			CreateAccountCoordinator()
		}
	}
}
