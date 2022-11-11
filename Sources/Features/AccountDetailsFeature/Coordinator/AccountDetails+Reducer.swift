import AggregatedValueFeature
import AssetsViewFeature
import ComposableArchitecture

public struct AccountDetails: ReducerProtocol {
	public init() {}

	public var body: some ReducerProtocol<State, Action> {
		Scope(state: \.aggregatedValue, action: /Action.child .. Action.ChildAction.aggregatedValue) {
			AggregatedValue()
		}

		Scope(state: \.assets, action: /Action.child .. Action.ChildAction.assets) {
			AssetsView()
		}

		Reduce { state, action in
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
	}
}
