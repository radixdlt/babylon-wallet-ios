import ComposableArchitecture

public extension Home.AggregatedValue {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { state, action, _ in
		switch action {
		case .internal(.user(.toggleVisibilityButtonTapped)):
			state.isVisible.toggle()
			return .none
		}
	}
}
