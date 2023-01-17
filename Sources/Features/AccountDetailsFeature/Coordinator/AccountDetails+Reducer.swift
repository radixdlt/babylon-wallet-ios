import AssetsViewFeature
import AssetTransferFeature
import FeaturePrelude

public struct AccountDetails: Sendable, ReducerProtocol {
	@Dependency(\.pasteboardClient) var pasteboardClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.assets, action: /Action.child .. Action.ChildAction.assets) {
			AssetsView()
		}

		Reduce(core)
			.presentationDestination(\.$destination, action: /Action.internal .. Action.InternalAction.destination) {
				Destinations()
			}
	}

	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.appeared)):
			return .run { [address = state.address] send in
				await send(.delegate(.refresh(address)))
			}
		case .internal(.view(.dismissAccountDetailsButtonTapped)):
			return .run { send in
				await send(.delegate(.dismissAccountDetails))
			}
		case .internal(.view(.displayAccountPreferencesButtonTapped)):
			return .run { [address = state.address] send in
				await send(.delegate(.displayAccountPreferences(address)))
			}
		case .internal(.view(.copyAddressButtonTapped)):
			let address = state.address.address
			return .fireAndForget { pasteboardClient.copyString(address) }
		case .internal(.view(.pullToRefreshStarted)):
			return .run { [address = state.address] send in
				await send(.delegate(.refresh(address)))
			}
		case .internal(.view(.transferButtonTapped)):
			state.destination = .transfer(AssetTransfer.State(from: state.account))
			return .none
		case .internal(.destination):
			return .none
		case .child, .delegate:
			return .none
		}
	}
}
