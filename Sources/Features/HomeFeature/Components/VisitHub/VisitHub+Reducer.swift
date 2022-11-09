import ComposableArchitecture

public extension Home.VisitHub {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { _, action, _ in
		switch action {
		case .internal(.view(.visitHubButtonTapped)):
			return Effect(value: .delegate(.displayHub))
		case .delegate:
			return .none
		}
	}
}
