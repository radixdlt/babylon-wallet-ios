import ConnectedDAppsFeature
import FeaturePrelude
import GatewayAPI
import ManageGatewayAPIEndpointsFeature
import ManageP2PClientsFeature
import PersonasFeature
import ProfileClient

// MARK: - AppSettings
public struct AppSettings: FeatureReducer {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.keychainClient) var keychainClient
	@Dependency(\.profileClient) var profileClient
	@Dependency(\.p2pConnectivityClient) var p2pConnectivityClient

	public typealias Store = StoreOf<Self>

	public init() {}

	// MARK: State

	public struct State: Sendable, Hashable {
		@PresentationState
		public var manageP2PClients: ManageP2PClients.State?
		@PresentationState
		public var connectedDapps: ConnectedDapps.State?
		@PresentationState
		public var manageGatewayAPIEndpoints: ManageGatewayAPIEndpoints.State?
		@PresentationState
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
		case loadP2PClientsResult(TaskResult<P2PClients>)
		#if DEBUG
		case profileToDebugLoaded(Profile)
		#endif
	}

	public enum ChildAction: Sendable, Equatable {
		case manageP2PClients(PresentationActionOf<ManageP2PClients>)
		case connectedDapps(PresentationActionOf<ConnectedDapps>)
		case manageGatewayAPIEndpoints(PresentationActionOf<ManageGatewayAPIEndpoints>)
		case personasCoordinator(PresentationActionOf<PersonasCoordinator>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismissSettings
		case deleteProfileAndFactorSources
		case networkChanged
	}

	// MARK: Reducer

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.presentationDestination(\.$manageP2PClients, action: /Action.child .. ChildAction.manageP2PClients) {
				ManageP2PClients()
			}
			.presentationDestination(\.$manageGatewayAPIEndpoints, action: /Action.child .. ChildAction.manageGatewayAPIEndpoints) {
				ManageGatewayAPIEndpoints()
			}
			.presentationDestination(\.$personasCoordinator, action: /Action.child .. ChildAction.personasCoordinator) {
				PersonasCoordinator()
			}
			.presentationDestination(\.$connectedDapps, action: /Action.child .. ChildAction.connectedDapps) {
				ConnectedDapps()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .didAppear:
			return loadP2PClients()

		case .dismissSettingsButtonTapped:
			return .send(.delegate(.dismissSettings))

		case .deleteProfileAndFactorSourcesButtonTapped:
			return .task {
				await p2pConnectivityClient.disconnectAndRemoveAll()
				return .delegate(.deleteProfileAndFactorSources)
			}

		case .manageP2PClientsButtonTapped:
			let presentedState = ManageP2PClients.State()
			return .send(.child(.manageP2PClients(.present(presentedState))))

		case .addP2PClientButtonTapped:
			let presentedState = ManageP2PClients.State(newConnection: .init())
			return .send(.child(.manageP2PClients(.present(presentedState))))

		case .editGatewayAPIEndpointButtonTapped:
			let presentedState = ManageGatewayAPIEndpoints.State()
			return .send(.child(.manageGatewayAPIEndpoints(.present(presentedState))))

		case .connectedDappsButtonTapped:
			let presentedState = ConnectedDapps.State()
			return .send(.child(.connectedDapps(.present(presentedState))))

		case .personasButtonTapped:
			// TODO: implement
			let presentedState = PersonasCoordinator.State()
			return .send(.child(.personasCoordinator(.present(presentedState))))

		#if DEBUG
		case .debugInspectProfileButtonTapped:
			return .run { send in
				guard let snapshot = try? await profileClient.extractProfileSnapshot(),
				      let profile = try? Profile(snapshot: snapshot) else { return }
				await send(.internal(.profileToDebugLoaded(profile)))
			}

		case let .setDebugProfileSheet(isPresented):
			precondition(!isPresented)
			state.profileToInspect = nil
			return .none
		#endif
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadP2PClientsResult(.success(clients)):
			state.canAddP2PClient = clients.isEmpty
			return .none

		case let .loadP2PClientsResult(.failure(error)):
			errorQueue.schedule(error)
			return .none

		#if DEBUG
		case let .profileToDebugLoaded(profile):
			state.profileToInspect = profile
			return .none
		#endif
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .manageP2PClients(.dismiss):
			return loadP2PClients()

		case .manageGatewayAPIEndpoints(.presented(.delegate(.networkChanged))):
			return .send(.delegate(.networkChanged))

		case .manageP2PClients,
		     .manageGatewayAPIEndpoints,
		     .connectedDapps,
		     .personasCoordinator:
			return .none
		}
	}
}

// MARK: Private
extension AppSettings {
	fileprivate func loadP2PClients() -> EffectTask<Action> {
		.task {
			await .internal(.loadP2PClientsResult(
				TaskResult { try await profileClient.getP2PClients() }
			))
		}
	}
}
