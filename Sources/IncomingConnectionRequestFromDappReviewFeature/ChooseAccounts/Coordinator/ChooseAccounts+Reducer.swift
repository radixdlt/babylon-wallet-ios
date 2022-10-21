import ComposableArchitecture

// MARK: - ChooseAccounts
public struct ChooseAccounts: ReducerProtocol {
	public init() {}
}

public extension ChooseAccounts {
	var body: some ReducerProtocol<State, Action> {
		Reduce { state, action in
			switch action {
			case .internal:
				return .none

			case let .account(id: id, action: action):
				guard let account = state.accounts[id: id] else { return .none }
				switch action {
				case .internal(.user(.didSelect)):
					if account.isSelected {
						state.selectedAccounts.removeAll(where: { $0.id == id })
						state.accounts[id: id]?.isSelected = false
					} else {
						guard state.selectedAccounts.count < state.accountLimit else { return .none }
						state.selectedAccounts.append(account)
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
