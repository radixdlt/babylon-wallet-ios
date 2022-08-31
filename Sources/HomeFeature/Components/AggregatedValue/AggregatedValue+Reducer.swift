import ComposableArchitecture

public extension Home.AggregatedValue {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<Home.AggregatedValueSubState, Action, Environment>
	static let reducer = Reducer { _, action, _ in
		switch action {
		case .internal(.user(.toggleVisibilityButtonTapped)):
			return Effect(value: .coordinate(.toggleIsCurrencyAmountVisible))
		case .coordinate:
			return .none
		}
	}
}
