import FeaturePrelude
import HomeFeature
import ProfileClient
import SettingsFeature

public struct Main: Sendable, ReducerProtocol {
	@Dependency(\.profileClient) var profileClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.home, action: /Action.child .. Action.ChildAction.home) {
			Home()
		}

		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. Action.ChildAction.destination) {
				Destinations()
			}
	}

	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .child(.home(.delegate(.displaySettings))):
			state.destination = .settings(.init())
			return .none

		case .child(.destination(.presented(.settings(.delegate(.deleteProfileAndFactorSources))))):
			return .run { send in
				try await profileClient.deleteProfileAndFactorSources()
				await send(.delegate(.removedWallet))
			}

		// this should go away via network stream observation in the reducer (with .task)
		case .child(.destination(.presented(.settings(.child(.destination(.presented(.manageGatewayAPIEndpoints(.delegate(.networkChanged))))))))):
			state.destination = nil
			state.home = .init()
			return .send(.child(.home(.view(.pullToRefreshStarted))))

		case .child(.destination(.presented(.settings(.delegate(.dismiss))))):
			state.destination = nil
			return .none

		case .view(.dappInteractionPresented):
			state.destination = nil
			return .none

		case .child, .delegate:
			return .none
		}
	}
}
