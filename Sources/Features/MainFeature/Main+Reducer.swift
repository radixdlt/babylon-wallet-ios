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

	public var body: some ReducerProtocol<State, Action> {
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
				try keychainClient.removeAllFactorSourcesAndProfileSnapshot()
				try await profileClient.deleteProfileSnapshot()
				await send(.delegate(.removedWallet))
			}

		case .child(.settings(.delegate(.dismissSettings))):
			state.settings = nil
			return .none

		case .child, .delegate:
			return .none
		}
	}
}
