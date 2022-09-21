import ComposableArchitecture

public extension AccountList.Row {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { _, action, _ in
		switch action {
		case .internal(.user(.copyAddress)):
			return .none
		case .internal(.user(.didSelect)):
			return .none
		}
	}
}
