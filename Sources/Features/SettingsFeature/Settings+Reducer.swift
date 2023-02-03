import FeaturePrelude
import GatewayAPI
import ManageGatewayAPIEndpointsFeature
import ManageP2PClientsFeature
import PersonasFeature
import ProfileClient

// MARK: - AppSettings
public struct AppSettings: Sendable, ReducerProtocol {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.keychainClient) var keychainClient
	@Dependency(\.profileClient) var profileClient
	@Dependency(\.p2pConnectivityClient) var p2pConnectivityClient

	public init() {}
}

public extension AppSettings {
	var body: some ReducerProtocolOf<Self> {
		Reduce(self.core)
			.ifLet(\.manageP2PClients, action: /Action.child .. Action.ChildAction.manageP2PClients) {
				ManageP2PClients()
			}
			.ifLet(\.manageGatewayAPIEndpoints, action: /Action.child .. Action.ChildAction.manageGatewayAPIEndpoints) {
				ManageGatewayAPIEndpoints()
			}
			.ifLet(\.personasCoordinator, action: /Action.child .. Action.ChildAction.personasCoordinator) {
				PersonasCoordinator()
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
				await p2pConnectivityClient.disconnectAndRemoveAll()
				await send(.delegate(.deleteProfileAndFactorSources))
			}

		case .internal(.view(.manageP2PClientsButtonTapped)):
			state.manageP2PClients = .init()
			return .none

		case .internal(.view(.didAppear)):
			return loadP2PClients()

		case let .internal(.system(.loadP2PClientsResult(.success(clients)))):
			state.canAddP2PClient = clients.isEmpty
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
		#endif

		case .child(.manageP2PClients(.delegate(.dismiss))):
			state.manageP2PClients = nil
			return loadP2PClients()

		case .child(.personasCoordinator(.delegate(.dismiss))):
			state.personasCoordinator = nil
			return .none

		case .child, .delegate:
			return .none

		case .internal(.view(.addP2PClientButtonTapped)):
			state.manageP2PClients = .init(newConnection: .init())
			return .none

		case .internal(.view(.editGatewayAPIEndpointButtonTapped)):
			state.manageGatewayAPIEndpoints = .init()
			return .none

		case .internal(.view(.personasButtonTapped)):
			// TODO: implement
			state.personasCoordinator = .init()
			return .none
		}
	}
}

// MARK: Private
private extension AppSettings {
	func loadP2PClients() -> EffectTask<Action> {
		.run { send in
			await send(.internal(.system(.loadP2PClientsResult(
				TaskResult { try await profileClient.getP2PClients() }
			))))
		}
	}
}
