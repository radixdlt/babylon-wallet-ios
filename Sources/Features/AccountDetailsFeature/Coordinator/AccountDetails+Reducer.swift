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
			.presentationDestination(\.$destination, action: /Action.child .. Action.ChildAction.destination) {
				Destinations()
			}
	}

	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.appeared)):
			return .run { [address = state.address] send in
				await send(.delegate(.refresh(address)))
			}
		case .internal(.view(.backButtonTapped)):
			return .run { send in
				await send(.delegate(.dismiss))
			}
		case .internal(.view(.preferencesButtonTapped)):
			state.destination = .preferences(.init(address: state.address))
			return .none
		case .internal(.view(.copyAddressButtonTapped)):
			let address = state.address.address
			return .fireAndForget { pasteboardClient.copyString(address) }
		case .internal(.view(.pullToRefreshStarted)):
			return .run { [address = state.address] send in
				await send(.delegate(.refresh(address)))
			}
		case .internal(.view(.transferButtonTapped)):
			// FIXME: fix post betanet v2
//			state.destination = .transfer(AssetTransfer.State(from: state.account))
			return .none
		case .child(.destination(.presented(.preferences(.delegate(.dismiss))))):
			state.destination = nil
			return .none
		case .child, .delegate:
			return .none
		}
	}
}
