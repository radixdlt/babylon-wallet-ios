import Collections
import ComposableArchitecture
import NonEmpty
import Profile

// MARK: - ChooseAccounts
public struct ChooseAccounts: ReducerProtocol {
	public init() {}

	public var body: some ReducerProtocol<State, Action> {
		Reduce { state, action in
			switch action {
			case .internal(.view(.continueButtonTapped)):
				let nonEmptySelectedAccounts = NonEmpty(rawValue: OrderedSet(state.accounts.filter(\.isSelected).map(\.account)))!
				return .run { send in
					await send(.delegate(.finishedChoosingAccounts(nonEmptySelectedAccounts)))
				}

			case .internal(.view(.backButtonTapped)):
				return .run { send in
					await send(.delegate(.dismissChooseAccounts))
				}

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

			case .delegate:
				return .none
			}
		}
		.forEach(\.accounts, action: /Action.child .. Action.ChildAction.account) {
			ChooseAccounts.Row()
		}
	}
}
