import ComposableArchitecture

public extension Home.AccountPreferences {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { _, action, _ in
		switch action {
		case .internal:
			return .none
		case .coordinate:
			return .none
		}
	}
}
