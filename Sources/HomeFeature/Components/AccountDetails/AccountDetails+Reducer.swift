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

		Reducer { state, action, _ in
			switch action {
			case .internal(.user(.dismissAccountDetails)):
				return .run { send in
					await send(.coordinate(.dismissAccountDetails))
				}
			case .internal(.user(.displayAccountPreferences)):
				return .run { send in
					await send(.coordinate(.displayAccountPreferences))
				}
			case .internal(.user(.copyAddress)):
				// FIXME: is this the right way to propagate state?
				// Since we're getting:
				// Reference to captured parameter 'state' in concurrently-executing code
				// if using state.address directly
				let address = state.address
				return .run { send in
					await send(.coordinate(.copyAddress(address)))
				}
			case .coordinate:
				return .none
			case .aggregatedValue:
				return .none
			}
		}
	)
}
