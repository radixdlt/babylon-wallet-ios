import ComposableArchitecture

public extension FungibleTokenList.Row {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { _, action, _ in
		switch action {
		case .internal:
			return .none
		case .delegate:
			return .none
		}
	}
}
