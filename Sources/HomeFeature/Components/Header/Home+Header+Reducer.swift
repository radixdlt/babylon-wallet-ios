import ComposableArchitecture

public extension Home.Header {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { _, action, _ in
		switch action {
		case let .internal(actions):
			switch actions {
			case let .user(userAction):
				switch userAction {
				case .settingsButtonTapped:
                    return Effect(value: .coordinate(.displaySettings))
				}
			case let .system(systemAction):
				break
			}
		case let .coordinate(coordinatingAction):
			break
		}
		return .none
	}
}
