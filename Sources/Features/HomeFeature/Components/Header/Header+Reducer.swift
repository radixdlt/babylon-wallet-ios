import ComposableArchitecture

public extension Home.Header {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { _, action, _ in
		switch action {
		case .internal(.view(.settingsButtonTapped)):
			return Effect(value: .delegate(.displaySettings))
		case .delegate:
			return .none
		}
	}
}
