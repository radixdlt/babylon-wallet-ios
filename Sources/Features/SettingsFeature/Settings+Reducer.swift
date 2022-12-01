import ComposableArchitecture
import ErrorQueue
import GatewayAPI
import KeychainClient
import ManageGatewayAPIEndpointsFeature
import ManageP2PClientsFeature
import Profile
import ProfileClient

// MARK: - Settings
public struct Settings: Sendable, ReducerProtocol {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.keychainClient) var keychainClient
	@Dependency(\.profileClient) var profileClient

	public init() {}
}

public extension Settings {
	var body: some ReducerProtocolOf<Self> {
		Reduce(self.core)
			.ifLet(\.manageP2PClients, action: /Action.child .. Action.ChildAction.manageP2PClients) {
				ManageP2PClients()
			}
			.ifLet(\.manageGatewayAPIEndpoints, action: /Action.child .. Action.ChildAction.manageGatewayAPIEndpoints) {
				ManageGatewayAPIEndpoints()
			}
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

		case .internal(.view(.manageP2PClientsButtonTapped)):
			state.manageP2PClients = .init()
			return .none

		case .internal(.view(.didAppear)):
			return .run { send in
				await send(.internal(.system(.loadP2PClientsResult(
					TaskResult { try await profileClient.getP2PClients() }
				))))
			}
		case let .internal(.system(.loadP2PClientsResult(.success(connections)))):
			state.canAddP2PClient = connections.connections.isEmpty
			return .none
		case let .internal(.system(.loadP2PClientsResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case .child(.manageGatewayAPIEndpoints(.delegate(.dismiss))):
			state.manageGatewayAPIEndpoints = nil
			return .none

		case .child(.manageGatewayAPIEndpoints(.delegate(.networkChanged))):
			return .run { send in
				await send(.delegate(.networkChanged))
			}

		case .child(.manageGatewayAPIEndpoints(.internal)):
			return .none

		#if DEBUG
		case .internal(.view(.debugInspectProfileButtonTapped)):
			return .run { send in
				guard
					let snapshot = try? await profileClient.extractProfileSnapshot(),
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

		case .child(.manageP2PClients(.delegate(.dismiss))):
			state.manageP2PClients = nil
			return .none

		case .child, .delegate:
			return .none
		case .internal(.view(.addP2PClientButtonTapped)):
			state.manageP2PClients = .init(inputP2PConnectionPassword: .init())
			return .none
		case .internal(.view(.editGatewayAPIEndpointButtonTapped)):
			state.manageGatewayAPIEndpoints = .init()
			return .none
		}
	}
}
