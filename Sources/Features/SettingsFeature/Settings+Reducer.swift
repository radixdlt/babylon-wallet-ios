import AppPreferencesClient
import AuthorizedDAppsFeature
import FeaturePrelude
import GatewayAPI
import LedgerHardwareDevicesFeature
import P2PLinksFeature
import PersonasFeature

// MARK: - Settings
public struct Settings: Sendable, FeatureReducer {
	public typealias Store = StoreOf<Self>

	public init() {}

	// MARK: State

	public struct State: Sendable, Hashable {
		@PresentationState
		public var destination: Destinations.State?

		public var userHasNoP2PLinks: Bool?

		public init() {}
	}

	// MARK: Action

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case addP2PLinkButtonTapped

		case authorizedDappsButtonTapped
		case personasButtonTapped
		case accountSecurityButtonTapped
		case appSettingsButtonTapped
		case debugButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case loadP2PLinksResult(TaskResult<P2PLinks>)
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case deleteProfileAndFactorSources(keepInICloudIfPresent: Bool)
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case manageP2PLinks(P2PLinksFeature.State)

			case authorizedDapps(AuthorizedDapps.State)
			case personas(PersonasCoordinator.State)
			case accountSecurity(AccountSecurity.State)
			case appSettings(AppSettings.State)
			case debugSettings(DebugSettings.State)
		}

		public enum Action: Sendable, Equatable {
			case manageP2PLinks(P2PLinksFeature.Action)

			case authorizedDapps(AuthorizedDapps.Action)
			case personas(PersonasCoordinator.Action)
			case accountSecurity(AccountSecurity.Action)
			case appSettings(AppSettings.Action)
			case debugSettings(DebugSettings.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.manageP2PLinks, action: /Action.manageP2PLinks) {
				P2PLinksFeature()
			}
			Scope(state: /State.authorizedDapps, action: /Action.authorizedDapps) {
				AuthorizedDapps()
			}
			Scope(state: /State.personas, action: /Action.personas) {
				PersonasCoordinator()
			}
			Scope(state: /State.accountSecurity, action: /Action.accountSecurity) {
				AccountSecurity()
			}
			Scope(state: /State.appSettings, action: /Action.appSettings) {
				AppSettings()
			}
			Scope(state: /State.debugSettings, action: /Action.debugSettings) {
				DebugSettings()
			}
		}
	}

	// MARK: Reducer

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.p2pLinksClient) var p2pLinksClient
	@Dependency(\.dismiss) var dismiss

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

		case .addP2PLinkButtonTapped:
			state.destination = .manageP2PLinks(.init(destination: .newConnection(.init())))
			return .none

		case .authorizedDappsButtonTapped:
			state.destination = .authorizedDapps(.init())
			return .none

		case .personasButtonTapped:
			state.destination = .personas(.init())
			return .none

		case .accountSecurityButtonTapped:
			state.destination = .accountSecurity(.init())
			return .none

		case .appSettingsButtonTapped:
			state.destination = .appSettings(.init())
			return .none

		case .debugButtonTapped:
			state.destination = .debugSettings(.init())
			return .none
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
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destination(.presented(.appSettings(.delegate(.deleteProfileAndFactorSources(keepInICloudIfPresent))))):
			return .send(.delegate(.deleteProfileAndFactorSources(keepInICloudIfPresent: keepInICloudIfPresent)))

		case .destination(.dismiss):
			switch state.destination {
			case .manageP2PLinks:
				return loadP2PLinks()
			default:
				return .none
			}

		case .destination:
			return .none
		}
	}
}

// MARK: Private
extension Settings {
	private func loadP2PLinks() -> EffectTask<Action> {
		.task {
			await .internal(.loadP2PLinksResult(
				TaskResult {
					await p2pLinksClient.getP2PLinks()
				}
			))
		}
	}
}
