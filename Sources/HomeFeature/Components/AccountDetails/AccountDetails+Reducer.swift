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
				return Effect(value: .coordinate(.dismissAccountDetails))
			case .internal(.user(.displayAccountPreferences)):
				return Effect(value: .coordinate(.displayAccountPreferences))
			case .internal(.user(.copyAddress)):
				return .run { [address = state.address] send in
					await send(.coordinate(.copyAddress(address)))
				}
			case .internal(.user(.refresh)):
				return Effect(value: .coordinate(.refresh(state.address)))
			case .coordinate:
				return .none
			case .aggregatedValue:
				return .none
			case .internal(.user(.displayTransfer)):
				return Effect(value: .coordinate(.displayTransfer))
			case .assetList:
				return .none
			}
		}
	)
}
