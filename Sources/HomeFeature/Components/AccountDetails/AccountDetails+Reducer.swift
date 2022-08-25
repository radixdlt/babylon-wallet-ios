import ComposableArchitecture

public extension Home.AccountDetails {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer.combine(
		Home.AggregatedValue.reducer
			.pullback(
				state: \.aggregatedValue,
				action: /Home.AccountDetails.Action.aggregatedValue,
				environment: { _ in Home.AggregatedValue.Environment() }
			),

		Reducer { _, action, _ in
			switch action {
			case .internal(.user(.dismissAccountDetails)):
				return .run { send in
					await send(.coordinate(.dismissAccountDetails))
				}
			case .internal(.user(.displayAccountPreferences)):
				return .run { send in
					await send(.coordinate(.displayAccountPreferences))
				}
			case .coordinate:
				return .none
			case .aggregatedValue:
				return .none
			}
		}
	)
}
