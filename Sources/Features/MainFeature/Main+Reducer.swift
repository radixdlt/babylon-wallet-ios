import ComposableArchitecture
import HomeFeature
import KeychainClient
import Profile
import ProfileClient
import SettingsFeature

public struct Main: ReducerProtocol {
	@Dependency(\.keychainClient) var keychainClient
	@Dependency(\.profileClient) var profileClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.home, action: /Action.child .. Action.ChildAction.home) {
			Home()
		}

		Reduce(self.core)
			.ifLet(\.settings, action: /Action.child .. Action.ChildAction.settings) {
				Settings()
			}
	}

	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .child(.home(.delegate(.displaySettings))):
			state.settings = .init()
			return .none

		case .child(.settings(.delegate(.deleteProfileAndFactorSources))):
			return .run { send in
				try await profileClient.deleteProfileAndFactorSources()
				await send(.delegate(.removedWallet))
			}

		case .child(.settings(.delegate(.dismissSettings))):
			state.settings = nil
			return .run { send in
				// Semi hacky way to cause Home to refetch connectionIDs which might have changed.
				// We can also add a boolean value to `.child(.settings(.delegate(.dismissSettings` action
				// which can indicate if you just added or removed a new P2P connection an only
				// call this if P2PClients have changed.
				await send(.child(.home(.internal(.view(.didAppear)))))
			}

		case .child, .delegate:
			return .none
		}
	}
}
