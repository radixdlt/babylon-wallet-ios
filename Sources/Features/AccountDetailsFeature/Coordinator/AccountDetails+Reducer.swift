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
				action: /AccountDetails.Action.child .. AccountDetails.Action.ChildAction.aggregatedValue,
				environment: { _ in AggregatedValue.Environment() }
			),

		AssetsView.reducer
			.pullback(
				state: \.assets,
				action: /AccountDetails.Action.child .. AccountDetails.Action.ChildAction.assets,
				environment: { _ in AssetsView.Environment() }
			),

		Reducer { state, action, _ in
			switch action {
			case .internal(.view(.dismissAccountDetailsButtonTapped)):
				return Effect(value: .delegate(.dismissAccountDetails))
			case .internal(.view(.displayAccountPreferencesButtonTapped)):
				return Effect(value: .delegate(.displayAccountPreferences))
			case .internal(.view(.copyAddressButtonTapped)):
				return .run { [address = state.address] send in
					await send(.delegate(.copyAddress(address)))
				}
			case .internal(.view(.refreshButtonTapped)):
				return Effect(value: .delegate(.refresh(state.address)))
			case .internal(.view(.transferButtonTapped)):
				return Effect(value: .delegate(.displayTransfer))
			case .child, .delegate:
				return .none
			}
		}
	)
}
