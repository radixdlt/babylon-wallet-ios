import AggregatedValueFeature
import AssetsViewFeature
import ComposableArchitecture

public extension AccountDetails {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer.combine(
		AggregatedValue.reducer
			.pullback(
				state: \.aggregatedValue,
				action: /AccountDetails.Action.child..AccountDetails.Action.ChildAction.aggregatedValue,
				environment: { _ in AggregatedValue.Environment() }
			),

		AssetsView.reducer
			.pullback(
				state: \.assets,
				action: /AccountDetails.Action.child..AccountDetails.Action.ChildAction.assets,
				environment: { _ in AssetsView.Environment() }
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
			case .internal(.user(.displayTransfer)):
				return Effect(value: .coordinate(.displayTransfer))
			case .child:
				return .none
			case .coordinate:
				return .none
			}
		}
	)
}
