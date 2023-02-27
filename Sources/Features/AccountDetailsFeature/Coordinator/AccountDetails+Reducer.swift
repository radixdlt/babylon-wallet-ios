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
			.ifLet(\.$destination, action: /Action.child .. Action.ChildAction.destination) {
				Destinations()
			}
	}

	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.appeared)):
			return .send(.delegate(.refresh(state.address)))
		case .internal(.view(.backButtonTapped)):
			return .send(.delegate(.dismiss))
		case .internal(.view(.preferencesButtonTapped)):
			state.destination = .preferences(.init(address: state.address))
			return .none
		case .internal(.view(.copyAddressButtonTapped)):
			return .fireAndForget { [address = state.address.address] in
				pasteboardClient.copyString(address)
			}
		case .internal(.view(.pullToRefreshStarted)):
			return .send(.delegate(.refresh(state.address)))
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
