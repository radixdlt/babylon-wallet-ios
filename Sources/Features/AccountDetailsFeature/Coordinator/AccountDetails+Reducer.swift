import AssetsViewFeature
import ComposableArchitecture

public struct AccountDetails: ReducerProtocol {
	public init() {}

	public var body: some ReducerProtocol<State, Action> {
		Scope(state: \.assets, action: /Action.child .. Action.ChildAction.assets) {
			AssetsView()
		}

		Reduce { state, action in
			switch action {
			case .internal(.view(.dismissAccountDetailsButtonTapped)):
				return .run { send in
					await send(.delegate(.dismissAccountDetails))
				}
			case .internal(.view(.displayAccountPreferencesButtonTapped)):
				return .run { send in
					await send(.delegate(.displayAccountPreferences))
				}
			case .internal(.view(.copyAddressButtonTapped)):
				return .run { [address = state.address] send in
					await send(.delegate(.copyAddress(address)))
				}
			case .internal(.view(.refreshButtonTapped)):
				return .run { [address = state.address] send in
					await send(.delegate(.refresh(address)))
				}
			case .internal(.view(.transferButtonTapped)):
				return .run { send in
					await send(.delegate(.displayTransfer))
				}
			case .child, .delegate:
				return .none
			}
		}
	}
}
