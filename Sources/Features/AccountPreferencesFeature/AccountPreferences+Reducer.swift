import ComposableArchitecture

public extension AccountPreferences {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { _, action, _ in
		switch action {
		case .internal(.view(.dismissButtonTapped)):
			return Effect(value: .delegate(.dismissAccountPreferences))
		case .delegate:
			return .none
		}
	}
}
