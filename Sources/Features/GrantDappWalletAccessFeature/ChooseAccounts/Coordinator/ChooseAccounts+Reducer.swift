import Collections
import ComposableArchitecture
import CreateAccountFeature
import ErrorQueue
import NonEmpty
import Profile
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
				let nonEmptySelectedAccounts = NonEmpty(rawValue: OrderedSet(state.accounts.filter(\.isSelected).map(\.account)))!
				return .run { [request = state.request] send in
					await send(.delegate(.finishedChoosingAccounts(nonEmptySelectedAccounts,
					                                               request)))
				}

			case .internal(.view(.dismissButtonTapped)):
				return .run { [request = state.request] send in
					await send(.delegate(.dismissChooseAccounts(request)))
				}

			case .internal(.view(.didAppear)):
				return .run { send in
					await send(.internal(.system(.loadAccountsResult(TaskResult {
						try await profileClient.getAccounts()
					}))))
				}

			case let .internal(.system(.loadAccountsResult(.success(accounts)))):
				state.accounts = .init(uniqueElements: accounts.map {
					ChooseAccounts.Row.State(account: $0)
				})
				return .none

			case let .internal(.system(.loadAccountsResult(.failure(error)))):
				errorQueue.schedule(error)
				return .none

			case .internal(.view(.createAccountButtonTapped)):
				state.createAccountFlow = .init(
					completionDestination: .chooseAccounts,
					rootState: .init()
				)
				return .none

			// FIXME: this logic belongs to the child instead, as only delegates should be intercepted via .child
			// and every other action should fall-through - @davdroman-rdx
			case let .child(.account(id: id, action: action)):
				guard let account = state.accounts[id: id] else { return .none }
				let oneTimeAccountRequest = state.request.requestItem
				switch action {
				case .internal(.view(.didSelect)):
					if account.isSelected {
						state.accounts[id: id]?.isSelected = false
					} else {
						switch oneTimeAccountRequest.numberOfAddresses {
						case .oneOrMore:
							state.accounts[id: id]?.isSelected = true
						case let .exactly(numberOfAddresses):
							guard state.selectedAccounts.count < numberOfAddresses.oneOrMore else { break }
							state.accounts[id: id]?.isSelected = true
						}
					}

					switch oneTimeAccountRequest.numberOfAddresses {
					case .oneOrMore:
						state.canProceed = state.selectedAccounts.count >= 1
					case let .exactly(numberOfAddresses):
						state.canProceed = state.selectedAccounts.count == numberOfAddresses.oneOrMore
					}

					return .none
				}

			case .child(.createAccountFlow(.delegate(.dismissed))):
				state.createAccountFlow = nil
				return .none

			case .child(.createAccountFlow(.delegate(.completed))):
				state.createAccountFlow = nil
				return .run { send in
					await send(.internal(.system(.loadAccountsResult(TaskResult {
						try await profileClient.getAccounts()
					}))))
				}

			case .delegate(.dismissChooseAccounts):
				state.createAccountFlow = nil
				return .none

			case .child, .delegate:
				return .none
			}
		}
		.forEach(\.accounts, action: /Action.child .. Action.ChildAction.account) {
			ChooseAccounts.Row()
		}
		.ifLet(\.createAccountFlow, action: /Action.child .. Action.ChildAction.createAccountFlow) {
			CreateAccountCoordinator()
		}
	}
}
