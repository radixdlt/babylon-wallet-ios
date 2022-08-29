import ComposableArchitecture

public extension Home.Header {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { _, action, _ in
		switch action {
		case .internal(.user(.settingsButtonTapped)):
			return .run { send in
				await send(.coordinate(.displaySettings))
			}
		case .coordinate:
			return .none
		}
	}
}
