import ComposableArchitecture

public extension AccountList {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer.combine(
		AccountList.Row.reducer.forEach(
			state: \.accounts,
			action: /Action.child .. Action.ChildAction.account,
			environment: { _ in AccountList.Row.Environment() }
		),

		Reducer { state, action, _ in
			switch action {
			case .delegate:
				return .none

			// FIXME: this logic belongs to the child instead, as only delegates should be intercepted via .child
			// and every other action should fall-through - @davdroman-rdx
			case let .child(.account(id: id, action: action)):
				guard let account = state.accounts[id: id] else {
					assertionFailure("Account value should not be nil.")
					return .none
				}
				switch action {
				case .internal(.user(.copyAddress)):
					return .run { send in
						await send(.delegate(.copyAddress(account.address)))
					}
				case .internal(.user(.didSelect)):
					return .run { send in
						await send(.delegate(.displayAccountDetails(account)))
					}
				}

			case .internal(.view(.alertDismissButtonTapped)):
				state.alert = nil
				return .none

			case .internal(.view(.viewAppeared)):
				return .run { send in
					await send(.delegate(.fetchPortfolioForAccounts))
				}
			}
		}
	)
}
