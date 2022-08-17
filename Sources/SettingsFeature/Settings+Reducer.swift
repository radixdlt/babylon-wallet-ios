import ComposableArchitecture

public extension Settings {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { _, action, _ in
		switch action {
		case .coordinate:
			return .none
		case .internal(.user(.dismissSettings)):
			return Effect(value: Settings.Action.coordinate(.dismissSettings))
		}
	}
}
