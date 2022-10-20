import ComposableArchitecture

public extension AccountList {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer.combine(
		AccountList.Row.reducer.forEach(
			state: \.accounts,
			action: /AccountList.Action.account(id:action:),
			environment: { _ in AccountList.Row.Environment() }
		),

		Reducer { state, action, _ in
			switch action {
			case .coordinate:
				return .none
			case let .account(id: id, action: action):
				guard let account = state.accounts.first(where: { $0.id == id }) else {
					preconditionFailure("Account value should not be nil.")
					return .none
				}
				switch action {
				case .internal(.user(.copyAddress)):
                    return Effect(value: .coordinate(.copyAddress(account.address)))
				case .internal(.user(.didSelect)):
					return Effect(value: .coordinate(.displayAccountDetails(account)))
				}
			case .internal(.user(.alertDismissed)):
				state.alert = nil
				return .none
			case .internal(.user(.loadAccounts)):
				return Effect(value: .coordinate(.loadAccounts))
			}
		}
	)
}
