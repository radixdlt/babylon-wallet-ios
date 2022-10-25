import ComposableArchitecture

// MARK: - ChooseAccounts
public struct ChooseAccounts: ReducerProtocol {
	public init() {}
}

public extension ChooseAccounts {
	var body: some ReducerProtocol<State, Action> {
		Reduce { state, action in
			switch action {
			case .internal(.user(.continueFromChooseAccounts)):
				return .run { send in
					await send(.coordinate(.dismissChooseAccounts))
				}

			case .internal(.user(.dismissChooseAccounts)):
				return .run { send in
					await send(.coordinate(.dismissChooseAccounts))
				}

			case .coordinate(.continueFromChooseAccounts):
				return .none

			case .coordinate(.dismissChooseAccounts):
				return .none

			case let .account(id: id, action: action):
				guard let account = state.accounts[id: id] else { return .none }
				switch action {
				case .internal(.user(.didSelect)):
					if account.isSelected {
						state.accounts[id: id]?.isSelected = false
					} else {
						guard state.selectedAccounts.count < state.accountLimit else { return .none }
						state.accounts[id: id]?.isSelected = true
					}

					state.isValid = state.selectedAccounts.count == state.accountLimit
					return .none
				}
			}
		}
		.forEach(\.accounts, action: /Action.account(id:action:)) {
			ChooseAccounts.Row()
		}
	}
}
