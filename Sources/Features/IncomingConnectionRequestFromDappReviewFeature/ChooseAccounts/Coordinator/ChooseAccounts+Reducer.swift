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
				switch action {
				case .internal(.view(.didSelect)):
					if account.isSelected {
						state.accounts[id: id]?.isSelected = false
					} else {
						switch state.incomingConnectionRequestFromDapp.numberOfNeededAccounts {
						case .atLeastOne:
							state.accounts[id: id]?.isSelected = true
						case let .exactly(number):
							guard state.selectedAccounts.count < number else { break }
							state.accounts[id: id]?.isSelected = true
						}
					}

					switch state.incomingConnectionRequestFromDapp.numberOfNeededAccounts {
					case .atLeastOne:
						state.canProceed = state.selectedAccounts.count >= 1
					case let .exactly(number):
						state.canProceed = state.selectedAccounts.count == number
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
