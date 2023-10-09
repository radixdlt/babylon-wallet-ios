import AppPreferencesClient
import DappsAndPersonasFeature
import FeaturePrelude
import GatewayAPI
import ImportLegacyWalletClient
import LedgerHardwareDevicesFeature
import P2PLinksFeature

// MARK: - Settings
public struct Settings: Sendable, FeatureReducer {
	public typealias Store = StoreOf<Self>

	public init() {}

	// MARK: State

	public struct State: Sendable, Hashable {
		@PresentationState
		public var destination: Destinations.State?

		public var shouldShowMigrateOlympiaButton: Bool = false
		public var userHasNoP2PLinks: Bool? = nil

		public init() {}
	}

	// MARK: Action

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case addP2PLinkButtonTapped
		case importOlympiaButtonTapped
		case dismissImportOlympiaHeaderButtonTapped

		case authorizedDappsButtonTapped
		case personasButtonTapped
		case accountSecurityButtonTapped
		case appSettingsButtonTapped
		case debugButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case loadedP2PLinks(P2PLinks)
		case loadedShouldShowImportWalletShortcutInSettings(Bool)
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case deleteProfileAndFactorSources(keepInICloudIfPresent: Bool)
	}

	public struct Destinations: Sendable, Reducer {
		public enum State: Sendable, Hashable {
			case manageP2PLinks(P2PLinksFeature.State)

			case authorizedDapps(AuthorizedDapps.State)
			case personas(PersonasCoordinator.State)
			case accountSecurity(AccountSecurity.State)
			case appSettings(AppSettings.State)
			case debugSettings(DebugSettingsCoordinator.State)
		}

		public enum Action: Sendable, Equatable {
			case manageP2PLinks(P2PLinksFeature.Action)

			case authorizedDapps(AuthorizedDapps.Action)
			case personas(PersonasCoordinator.Action)
			case accountSecurity(AccountSecurity.Action)
			case appSettings(AppSettings.Action)
			case debugSettings(DebugSettingsCoordinator.Action)
		}

		public var body: some ReducerOf<Self> {
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
			#if DEBUG
			Scope(state: /State.debugSettings, action: /Action.debugSettings) {
				DebugSettingsCoordinator()
			}
			#endif
		}
	}

	// MARK: Reducer

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.p2pLinksClient) var p2pLinksClient
	@Dependency(\.dismiss) var dismiss
	@Dependency(\.userDefaultsClient) var userDefaultsClient

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return loadShouldShowImportWalletShortcutInSettings()
				.concatenate(
					with: loadP2PLinks()
				)

		case .addP2PLinkButtonTapped:
			state.destination = .manageP2PLinks(.init(destination: .newConnection(.init())))
			return .none

		case .importOlympiaButtonTapped:
			state.destination = .accountSecurity(.importOlympia)
			return .none

		case .dismissImportOlympiaHeaderButtonTapped:
			return hideImportOlympiaHeader(in: &state)

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

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadedShouldShowImportWalletShortcutInSettings(shouldShow):
			state.shouldShowMigrateOlympiaButton = shouldShow
			return .none

		case let .loadedP2PLinks(clients):
			state.userHasNoP2PLinks = clients.isEmpty
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .destination(.presented(presentedAction)):
			switch presentedAction {
			case let .appSettings(.delegate(.deleteProfileAndFactorSources(keepInICloudIfPresent))):
				return .send(.delegate(.deleteProfileAndFactorSources(keepInICloudIfPresent: keepInICloudIfPresent)))
			case .accountSecurity(.delegate(.gotoAccountList)):
				return .run { _ in await dismiss() }
			default:
				return .none
			}

		case .destination(.dismiss):
			switch state.destination {
			case .manageP2PLinks:
				return loadP2PLinks()
			default:
				return .none
			}
		}
	}

	private func hideImportOlympiaHeader(in state: inout State) -> Effect<Action> {
		state.shouldShowMigrateOlympiaButton = false
		return .run { _ in
			await userDefaultsClient.setHideMigrateOlympiaButton(true)
		}
	}
}

// MARK: Private
extension Settings {
	private func loadP2PLinks() -> Effect<Action> {
		.run { send in
			await send(.internal(.loadedP2PLinks(
				p2pLinksClient.getP2PLinks()
			)))
		}
	}

	private func loadShouldShowImportWalletShortcutInSettings() -> Effect<Action> {
		.run { send in
			@Dependency(\.importLegacyWalletClient) var importLegacyWalletClient
			let shouldShow = await importLegacyWalletClient.shouldShowImportWalletShortcutInSettings()
			await send(.internal(.loadedShouldShowImportWalletShortcutInSettings(shouldShow)))
		}
	}
}
