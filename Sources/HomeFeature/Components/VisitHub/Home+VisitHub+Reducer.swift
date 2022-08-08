import ComposableArchitecture

public extension Home.VisitHub {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { _, action, _ in
		switch action {
		case .internal(.user(.visitHubButtonTapped)):
			return Effect(value: .coordinate(.displayHub))
		case .coordinate:
			return .none
		}
	}
}
