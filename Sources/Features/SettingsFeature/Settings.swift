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
	@Dependency(\.profileClient) var profileClient
	@Dependency(\.p2pConnectivityClient) var p2pConnectivityClient

	public typealias Store = StoreOf<Self>

	public init() {}

	// MARK: State

	public struct State: Sendable, Hashable {
		@PresentationState
		public var destination: Destinations.State?

		public var userHasNoP2PClients: Bool?
		#if DEBUG
		public var profileToInspect: Profile?
		#endif

		public init() {}
	}

	// MARK: Action

	public enum ViewAction: Sendable, Equatable {
		case didAppear
		case closeButtonTapped
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
		case destination(PresentationActionOf<Destinations>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss // TODO: remove this and use @Dependency(\.dismiss) when TCA tools are released
		case deleteProfileAndFactorSources
		case networkChanged
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case manageP2PClients(ManageP2PClients.State)
			case manageGatewayAPIEndpoints(ManageGatewayAPIEndpoints.State)
			case connectedDapps(ConnectedDapps.State)
			case personas(PersonasCoordinator.State)
		}

		public enum Action: Sendable, Equatable {
			case manageP2PClients(ManageP2PClients.Action)
			case manageGatewayAPIEndpoints(ManageGatewayAPIEndpoints.Action)
			case connectedDapps(ConnectedDapps.Action)
			case personas(PersonasCoordinator.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.manageP2PClients, action: /Action.manageP2PClients) {
				ManageP2PClients()
			}
			Scope(state: /State.manageGatewayAPIEndpoints, action: /Action.manageGatewayAPIEndpoints) {
				ManageGatewayAPIEndpoints()
			}
			Scope(state: /State.connectedDapps, action: /Action.connectedDapps) {
				ConnectedDapps()
			}
			Scope(state: /State.personas, action: /Action.personas) {
				PersonasCoordinator()
			}
		}
	}

	// MARK: Reducer

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.presentationDestination(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .didAppear:
			return loadP2PClients()

		case .closeButtonTapped:
			return .send(.delegate(.dismiss))

		case .deleteProfileAndFactorSourcesButtonTapped:
			return .task {
				await p2pConnectivityClient.disconnectAndRemoveAll()
				return .delegate(.deleteProfileAndFactorSources)
			}

		case .addP2PClientButtonTapped:
			state.destination = .manageP2PClients(.init(destination: .newConnection(.init())))
			return .none

		case .manageP2PClientsButtonTapped:
			state.destination = .manageP2PClients(.init())
			return .none

		case .editGatewayAPIEndpointButtonTapped:
			state.destination = .manageGatewayAPIEndpoints(.init())
			return .none

		case .connectedDappsButtonTapped:
			state.destination = .connectedDapps(.init())
			return .none

		case .personasButtonTapped:
			// TODO: implement
			state.destination = .personas(.init())
			return .none

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
			state.userHasNoP2PClients = clients.isEmpty
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
//		case .destination(.presented(.manageP2PClients(.dismiss))):
//			return loadP2PClients()
//
//		case .destination(.presented(.manageGatewayAPIEndpoints(.presented(.delegate(.networkChanged))))):
//			return .send(.delegate(.networkChanged))

		case .destination:
			return .none
		}
	}
}

// MARK: Private
extension AppSettings {
	fileprivate func loadP2PClients() -> EffectTask<Action> {
		.task {
			await .internal(.loadP2PClientsResult(
				TaskResult {
					try await profileClient.getP2PClients()
				}
			))
		}
	}
}
