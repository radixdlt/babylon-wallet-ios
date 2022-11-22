import ComposableArchitecture
import HandleDappRequests
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

		Scope(state: \.handleDappRequests, action: /Action.child .. Action.ChildAction.handleDappRequest) {
			HandleDappRequests()
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
			return .none

		case .child, .delegate:
			return .none
		}
	}
}
