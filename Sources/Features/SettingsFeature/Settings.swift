import ConnectedDAppsFeature
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

	public typealias Store = StoreOf<Self>

	public init() {}

	// MARK: State

	public struct State: Equatable {
		public var manageP2PClients: ManageP2PClients.State?
		@PresentationState public var connectedDapps: ConnectedDapps.State?
		public var manageGatewayAPIEndpoints: ManageGatewayAPIEndpoints.State?
		public var personasCoordinator: PersonasCoordinator.State?
		public var canAddP2PClient: Bool
		#if DEBUG
		public var profileToInspect: Profile?
		#endif

		public init(manageP2PClients: ManageP2PClients.State? = nil,
		            connectedDapps: ConnectedDapps.State? = nil,
		            manageGatewayAPIEndpoints: ManageGatewayAPIEndpoints.State? = nil,
		            personasCoordinator: PersonasCoordinator.State? = nil,
		            canAddP2PClient: Bool = false)
		{
			self.manageP2PClients = manageP2PClients
			self.connectedDapps = connectedDapps
			self.manageGatewayAPIEndpoints = manageGatewayAPIEndpoints
			self.personasCoordinator = personasCoordinator
			self.canAddP2PClient = canAddP2PClient
		}
	}

	// MARK: Action

	public enum Action: Sendable, Equatable {
		case child(ChildAction)
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}

	public enum ChildAction: Sendable, Equatable {
		case manageP2PClients(ManageP2PClients.Action)
		case connectedDapps(PresentationActionOf<ConnectedDapps>)
		case manageGatewayAPIEndpoints(ManageGatewayAPIEndpoints.Action)
		case personasCoordinator(PersonasCoordinator.Action)
	}

	public enum ViewAction: Sendable, Equatable {
		case didAppear
		case dismissSettingsButtonTapped
		case deleteProfileAndFactorSourcesButtonTapped

		case manageP2PClientsButtonTapped
		case addP2PClientButtonTapped

		case editGatewayAPIEndpointButtonTapped
		case connectedDappsButtonTapped
		case personasButtonTapped

		#if DEBUG
		case debugInspectProfileButtonTapped
		case setDebugProfileSheet(isPresented: Bool)
		#endif
	}

	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}

	public enum SystemAction: Sendable, Equatable {
		case loadP2PClientsResult(TaskResult<P2PClients>)
		#if DEBUG
		case profileToDebugLoaded(Profile)
		#endif
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismissSettings
		case deleteProfileAndFactorSources
		case networkChanged
	}

	// MARK: Reducer

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.manageP2PClients, action: /Action.child .. ChildAction.manageP2PClients) {
				ManageP2PClients()
			}
			.ifLet(\.manageGatewayAPIEndpoints, action: /Action.child .. ChildAction.manageGatewayAPIEndpoints) {
				ManageGatewayAPIEndpoints()
			}
			.ifLet(\.personasCoordinator, action: /Action.child .. ChildAction.personasCoordinator) {
				PersonasCoordinator()
			}
			.presentationDestination(\.$connectedDapps, action: /Action.child .. ChildAction.connectedDapps) {
				ConnectedDapps()
			}
	}

	public func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.dismissSettingsButtonTapped)):
			return .send(.delegate(.dismissSettings))

		case .internal(.view(.deleteProfileAndFactorSourcesButtonTapped)):
			return .run { send in
				await p2pConnectivityClient.disconnectAndRemoveAll()
				await send(.delegate(.deleteProfileAndFactorSources))
			}

		case .internal(.view(.manageP2PClientsButtonTapped)):
			state.manageP2PClients = .init()
			return .none

		case .internal(.view(.connectedDappsButtonTapped)):
			// TODO: This proxying is only necessary because of our strict view/child separation
			return .send(.child(.connectedDapps(.present(.init()))))

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

		case .internal, .child, .delegate:
			return .none
		}
	}
}

// MARK: Private
extension AppSettings {
	fileprivate func loadP2PClients() -> EffectTask<Action> {
		.run { send in
			await send(.internal(.system(.loadP2PClientsResult(
				TaskResult { try await profileClient.getP2PClients() }
			))))
		}
	}
}
