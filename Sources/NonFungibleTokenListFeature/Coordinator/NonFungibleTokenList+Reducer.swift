import ComposableArchitecture

public extension NonFungibleTokenList {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer.combine(
		NonFungibleTokenList.Row.reducer.forEach(
			state: \.rows,
			action: /NonFungibleTokenList.Action.asset(id:action:),
			environment: { _ in NonFungibleTokenList.Row.Environment() }
		),

		Reducer { _, action, _ in
			switch action {
			case .internal:
				return .none
			case .coordinate:
				return .none
			case let .asset(id: id, action: action):
				return .none
			}
		}
	)
}
