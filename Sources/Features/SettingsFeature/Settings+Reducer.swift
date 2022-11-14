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
			.ifLet(\.manageBrowserExtensionConnections, action: /Action.child .. Action.ChildAction.manageBrowserExtensionConnections) {
				ManageBrowserExtensionConnections()
			}
			._printChanges()
	}

	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.dismissSettingsButtonTapped)):
			return .run { send in
				await send(.delegate(.dismissSettings))
			}

		case .internal(.view(.deleteProfileAndFactorSourcesButtonTapped)):
			return .run { send in
				await send(.delegate(.deleteProfileAndFactorSources))
			}

		case .internal(.view(.manageBrowserExtensionConnectionsButtonTapped)):
			state.manageBrowserExtensionConnections = .init()
			return .none

		case .internal(.view(.didAppear)):
			return .run { send in
				await send(.internal(.system(.loadBrowserExtensionConnectionResult(
					TaskResult { try profileClient.getBrowserExtensionConnections() }
				))))
			}
		case let .internal(.system(.loadBrowserExtensionConnectionResult(.success(connections)))):
			state.canAddBrowserExtensionConnection = connections.connections.isEmpty
			return .none
		case let .internal(.system(.loadBrowserExtensionConnectionResult(.failure(error)))):
			print("Failed to load browser extensions: \(String(describing: error))")
			// FIXME: Error propagation
			return .none

		case .child(.manageGatewayAPIEndpoints):
			fatalError("IMPLE ME")

		#if DEBUG
		case .internal(.view(.debugInspectProfileButtonTapped)):
			return .run { send in
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

		case let .internal(.view(.setDebugProfileSheet(isPresented))):
			precondition(!isPresented)
			state.profileToInspect = nil
			return .none
		#endif // DEBUG

		case .child(.manageBrowserExtensionConnections(.delegate(.dismiss))):
			state.manageBrowserExtensionConnections = nil
			return .none

		case .child, .delegate:
			return .none
		case .internal(.view(.addBrowserExtensionConnectionButtonTapped)):
			state.manageBrowserExtensionConnections = .init(inputBrowserExtensionConnectionPassword: .init())
			return .none
		case .internal(.view(.editGatewayAPIEndpointButtonTapped)):
			state.manageGatewayAPIEndpoints = .init()
			return .none
		}
	}
}
