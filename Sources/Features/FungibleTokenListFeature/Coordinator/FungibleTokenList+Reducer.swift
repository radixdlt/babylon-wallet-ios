import ComposableArchitecture

public extension FungibleTokenList {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer.combine(
		FungibleTokenList.Section.reducer.forEach(
			state: \.sections,
			action: /Action.child .. Action.ChildAction.section,
			environment: { _ in FungibleTokenList.Section.Environment() }
		),

		Reducer { _, action, _ in
			switch action {
			case .internal:
				return .none
			case .child, .delegate:
				return .none
			}
		}
	)
}
