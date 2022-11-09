import ComposableArchitecture

public extension AggregatedValue {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { _, action, _ in
		switch action {
		case .internal(.view(.toggleVisibilityButtonTapped)):
			return Effect(value: .delegate(.toggleIsCurrencyAmountVisible))
		case .delegate:
			return .none
		}
	}
}
