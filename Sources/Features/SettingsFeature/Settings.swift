import AppPreferencesClient
import AuthorizedDAppsFeatures
import FeaturePrelude
import GatewayAPI
import GatewaySettingsFeature
import GeneralSettings
import P2PLinksFeature
import PersonasFeature

// MARK: - AppSettings
public struct AppSettings: FeatureReducer {
	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.p2pLinksClient) var p2pLinksClient
	@Dependency(\.radixConnectClient) var radixConnectClient

	public typealias Store = StoreOf<Self>

	public init() {}

	// MARK: State

	public struct State: Sendable, Hashable {
		@PresentationState
		public var destination: Destinations.State?

		public var userHasNoP2PLinks: Bool?
		#if DEBUG
		public var profileToInspect: Profile?
		#endif

		public init() {}
	}

	// MARK: Action

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case backButtonTapped
		case deleteProfileAndFactorSourcesButtonTapped

		case manageP2PLinksButtonTapped
		case addP2PLinkButtonTapped

		case gatewaysButtonTapped
		case authorizedDappsButtonTapped
		case personasButtonTapped
		case generalSettingsButtonTapped
		case factorSourcesButtonTapped
		case importFromOlympiaWalletButtonTapped

		#if DEBUG
		case debugInspectProfileButtonTapped
		case setDebugProfileSheet(isPresented: Bool)
		#endif
	}

	public enum InternalAction: Sendable, Equatable {
		case loadP2PLinksResult(TaskResult<P2PLinks>)
		#if DEBUG
		case profileToDebugLoaded(Profile)
		#endif
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss // TODO: remove this and use @Dependency(\.dismiss) when TCA tools are released
		case deleteProfileAndFactorSources
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case importOlympiaWalletCoordinator(ImportOlympiaWalletCoordinator.State)
			case manageFactorSources(ManageFactorSources.State)
			case manageP2PLinks(P2PLinksFeature.State)
			case gatewaySettings(GatewaySettings.State)
			case authorizedDapps(AuthorizedDapps.State)
			case personas(PersonasCoordinator.State)
			case generalSettings(GeneralSettings.State)
		}

		public enum Action: Sendable, Equatable {
			case importOlympiaWalletCoordinator(ImportOlympiaWalletCoordinator.Action)
			case manageFactorSources(ManageFactorSources.Action)
			case manageP2PLinks(P2PLinksFeature.Action)
			case gatewaySettings(GatewaySettings.Action)
			case authorizedDapps(AuthorizedDapps.Action)
			case personas(PersonasCoordinator.Action)
			case generalSettings(GeneralSettings.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.importOlympiaWalletCoordinator, action: /Action.importOlympiaWalletCoordinator) {
				ImportOlympiaWalletCoordinator()._printChanges()
			}
			Scope(state: /State.manageFactorSources, action: /Action.manageFactorSources) {
				ManageFactorSources()
			}
			Scope(state: /State.manageP2PLinks, action: /Action.manageP2PLinks) {
				P2PLinksFeature()
			}
			Scope(state: /State.gatewaySettings, action: /Action.gatewaySettings) {
				GatewaySettings()
			}
			Scope(state: /State.authorizedDapps, action: /Action.authorizedDapps) {
				AuthorizedDapps()
			}
			Scope(state: /State.personas, action: /Action.personas) {
				PersonasCoordinator()
			}
			Scope(state: /State.generalSettings, action: /Action.generalSettings) {
				GeneralSettings()
			}
		}
	}

	// MARK: Reducer

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return loadP2PLinks()

		case .backButtonTapped:
			return .send(.delegate(.dismiss))

		case .deleteProfileAndFactorSourcesButtonTapped:
			return .task {
				await radixConnectClient.disconnectAndRemoveAll()
				return .delegate(.deleteProfileAndFactorSources)
			}

		case .factorSourcesButtonTapped:
			state.destination = .manageFactorSources(.init())
			return .none

		case .importFromOlympiaWalletButtonTapped:
			state.destination = .importOlympiaWalletCoordinator(.init())
			return .none

		case .addP2PLinkButtonTapped:
			state.destination = .manageP2PLinks(.init(destination: .newConnection(.init())))
			return .none

		case .manageP2PLinksButtonTapped:
			state.destination = .manageP2PLinks(.init())
			return .none

		case .gatewaysButtonTapped:
			state.destination = .gatewaySettings(.init())
			return .none

		case .authorizedDappsButtonTapped:
			state.destination = .authorizedDapps(.init())
			return .none

		case .personasButtonTapped:
			// TODO: implement
			state.destination = .personas(.init())
			return .none

		case .generalSettingsButtonTapped:
			state.destination = .generalSettings(.init())
			return .none

		#if DEBUG
		case .debugInspectProfileButtonTapped:
			return .run { send in
				let snapshot = await appPreferencesClient.extractProfileSnapshot()
				guard let profile = try? Profile(snapshot: snapshot) else { return }
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
		case let .loadP2PLinksResult(.success(clients)):
			state.userHasNoP2PLinks = clients.isEmpty
			return .none

		case let .loadP2PLinksResult(.failure(error)):
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
		case .destination(.dismiss):
			switch state.destination {
			case .manageP2PLinks:
				return loadP2PLinks()
			default:
				return .none
			}

		case .destination(.presented(.importOlympiaWalletCoordinator(.delegate(.dismiss)))):
			state.destination = nil
			return .none

		case .destination(.presented(.importOlympiaWalletCoordinator(.delegate(.finishedMigration)))):
			state.destination = nil
			return .none

		case .destination:
			return .none
		}
	}
}

// MARK: Private
extension AppSettings {
	fileprivate func loadP2PLinks() -> EffectTask<Action> {
		.task {
			await .internal(.loadP2PLinksResult(
				TaskResult {
					try await p2pLinksClient.getP2PLinks()
				}
			))
		}
	}
}
