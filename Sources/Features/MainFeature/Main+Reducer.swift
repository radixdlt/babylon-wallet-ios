import ComposableArchitecture
import HomeFeature
import KeychainClient
import Profile
import ProfileClient
import SettingsFeature

// #if os(iOS)
//// FIXME: move to `UIApplicationClient` package!
// import UIKit
// #endif

public struct Main: ReducerProtocol {
	public init() {}

	@Dependency(\.keychainClient) var keychainClient
	@Dependency(\.profileClient) var profileClient

	public var body: some ReducerProtocol<State, Action> {
		Scope(state: \.home, action: /Action.child .. Action.ChildAction.home) {
			Home()
		}

		Reduce { state, action in
			switch action {
			case .child(.home(.delegate(.displaySettings))):
				state.settings = .init()
				return .none

			case .child(.settings(.delegate(.deleteProfileAndFactorSources))):
				return .run { [keychainClient, profileClient] send in
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
		.ifLet(\.settings, action: /Action.child .. Action.ChildAction.settings) {
			Settings()
		}
	}
}
