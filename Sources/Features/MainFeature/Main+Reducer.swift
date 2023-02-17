import FeaturePrelude
import HomeFeature
import ProfileClient
import SettingsFeature

public struct Main: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var home: Home.State
		// TODO: @Nikola uncomment
//		public var settings: AppSettings.State?

		public init(
			home: Home.State = .init()
			// TODO: @Nikola uncomment
//			settings: AppSettings.State? = nil
		) {
			self.home = home
			// TODO: @Nikola uncomment
//			self.settings = settings
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case home(Home.Action)
		case settings(AppSettings.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case removedWallet
	}

	@Dependency(\.keychainClient) var keychainClient
	@Dependency(\.profileClient) var profileClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.home, action: /Action.child .. ChildAction.home) {
			Home()
		}

		Reduce(core)
			.presentationDestination(\.$destination, action: /Action.child .. Action.ChildAction.destination) {
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
	 */
}
