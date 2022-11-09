import ComposableArchitecture
import GatewayAPI
import KeychainClient
import ManageBrowserExtensionConnectionsFeature
import Profile
import ProfileClient

// MARK: - Settings
public struct Settings: ReducerProtocol {
	@Dependency(\.keychainClient) var keychainClient
	@Dependency(\.profileClient) var profileClient

	public init() {}
}

public extension Settings {
	var body: some ReducerProtocol<State, Action> {
		Reduce(self.core)
			.ifLet(\
				.manageBrowserExtensionConnections,
				action: /Action.child..Action.ChildAction.manageBrowserExtensionConnections) {
					ManageBrowserExtensionConnections()
			}
			._printChanges()
	}

	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.system(.viewDidAppear)):
			return .none

		case .internal(.user(.dismissSettings)):
			return .run { send in
				await send(.delegate(.dismissSettings))
			}

		case .internal(.user(.deleteProfileAndFactorSources)):
			return .run { send in
				await send(.delegate(.deleteProfileAndFactorSources))
			}

		case .internal(.user(.goToBrowserExtensionConnections)):
			state.manageBrowserExtensionConnections = .init()
			return .none

		#if DEBUG
		case .internal(.user(.debugInspectProfile)):

			return .run { [profileClient] send in
				guard
					let snapshot = try? profileClient.extractProfileSnapshot(),
					let profile = try? Profile(snapshot: snapshot)
				else {
					return
				}
				await send(.internal(.system(.profileToDebugLoaded(profile))))
			}
		case let .internal(.system(.profileToDebugLoaded(profile))):
			state.profileToInspect = profile
			return .none

		case let .internal(.user(.setDebugProfileSheet(isPresented))):
			precondition(!isPresented)
			state.profileToInspect = nil
			return .none
		#endif // DEBUG

		case .child(.manageBrowserExtensionConnections(.delegate(.dismiss))):
			state.manageBrowserExtensionConnections = nil
			return .none

		case .child, .delegate:
			return .none
		}
	}
}
