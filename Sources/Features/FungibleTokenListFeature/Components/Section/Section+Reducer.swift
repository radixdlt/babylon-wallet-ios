import ComposableArchitecture

public extension FungibleTokenList.Section {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer.combine(
		FungibleTokenList.Row.reducer.forEach(
			state: \.assets,
			action: /Action.child .. Action.ChildAction.asset,
			environment: { _ in FungibleTokenList.Row.Environment() }
		),

		Reducer { _, action, _ in
			switch action {
			case .internal:
				return .none
			case .child:
				return .none
			case .delegate:
				return .none
			}
		}
	)
}
