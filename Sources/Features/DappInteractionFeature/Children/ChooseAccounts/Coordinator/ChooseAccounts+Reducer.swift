import CreateEntityFeature
import FeaturePrelude
import ProfileClient

// MARK: - ChooseAccounts
public struct ChooseAccounts: Sendable, ReducerProtocol {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.profileClient) var profileClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce { state, action in
			switch action {
			case .internal(.view(.continueButtonTapped)):
				let selectedAccounts = IdentifiedArrayOf(uniqueElements: state.selectedAccounts.map(\.account))
				return .run { send in
					await send(.delegate(.continueButtonTapped(selectedAccounts)))
				}

			case .internal(.view(.dismissButtonTapped)):
				return .run { send in
					await send(.delegate(.dismissButtonTapped))
				}

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

			// FIXME: this logic belongs to the child instead, as only delegates should be intercepted via .child
			// and every other action should fall-through - @davdroman-rdx
			case let .child(.account(id: id, action: action)):
				guard let account = state.availableAccounts[id: id] else { return .none }
				switch action {
				case .internal(.view(.didSelect)):
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
				}

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

			case .delegate(.dismissButtonTapped):
				// TODO: @Nikola this is an unnedeed bit of logic afaik, as the dismiss button is unreachable when create account is present
				// Verify this is true and if so please do remove it :)
				// If we do need it for some reason, declare a separate action to do so, as we shouldn't be layering behavior onto our own delegates like this (it makes testing reasoning harder).
				state.createAccountCoordinator = nil
				return .none

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
