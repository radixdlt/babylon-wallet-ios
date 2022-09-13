import ComposableArchitecture

public extension Home.AssetList {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { _, action, _ in
		switch action {
		case .internal:
			return .none
		case .coordinate:
			return .none
		case let .asset(id: id, action: action):
			// TODO: implement
			print(id, action)
			return .none
		case let .xrdAction(action: action):
			return .none
		}
	}
}
