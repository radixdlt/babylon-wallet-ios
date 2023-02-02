import DappInteractionHookFeature
import FeaturePrelude
import HomeFeature
import ProfileClient
import SettingsFeature

public struct Main: Sendable, ReducerProtocol {
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
				AppSettings()
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

		case .child(.settings(.delegate(.networkChanged))):
			state.settings = nil
			state.home = .init()
			return body.reduce(into: &state, action: .child(.home(.internal(.view(.pullToRefreshStarted)))))

		case .child(.settings(.delegate(.dismissSettings))):
			state.settings = nil
			return .none

		case .child(.handleDappRequest(.child(.chooseAccounts(.child(.createAccountCoordinator(.delegate(.completed))))))):
			return .run { send in
				await send(.child(.home(.delegate(.reloadAccounts))))
			}

		case .child, .delegate:
			return .none
		}
	}
}
