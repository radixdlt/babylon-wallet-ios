import AccountsClient
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

		public var shouldShowMigrateOlympiaButton: Bool
		public var userHasNoP2PLinks: Bool? = nil

		public init() {
			@Dependency(\.userDefaultsClient) var userDefaultsClient: UserDefaultsClient
			self.shouldShowMigrateOlympiaButton = !userDefaultsClient.hideMigrateOlympiaButtonKey
		}
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
		case loadAccountsResult(TaskResult<Profile.Network.Accounts>)
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
			case importOlympiaWallet(ImportOlympiaWalletCoordinator.State)

			case authorizedDapps(AuthorizedDapps.State)
			case personas(PersonasCoordinator.State)
			case accountSecurity(AccountSecurity.State)
			case appSettings(AppSettings.State)
			case debugSettings(DebugSettings.State)
		}

		public enum Action: Sendable, Equatable {
			case manageP2PLinks(P2PLinksFeature.Action)
			case importOlympiaWallet(ImportOlympiaWalletCoordinator.Action)

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
			Scope(state: /State.importOlympiaWallet, action: /Action.importOlympiaWallet) {
				ImportOlympiaWalletCoordinator()
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

	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.p2pLinksClient) var p2pLinksClient
	@Dependency(\.dismiss) var dismiss
	@Dependency(\.userDefaultsClient) var userDefaultsClient

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			// We don't need to load the accounts if they have dismissed the olympia header before
			return loadP2PLinks(andAccounts: state.shouldShowMigrateOlympiaButton)

		case .addP2PLinkButtonTapped:
			state.destination = .manageP2PLinks(.init(destination: .newConnection(.init())))
			return .none

		case .importOlympiaButtonTapped:
			state.destination = .importOlympiaWallet(.init())
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

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadedP2PLinks(clients):
			state.userHasNoP2PLinks = clients.isEmpty
			return .none

		case let .loadAccountsResult(.success(accounts)):
			if accounts.contains(where: \.isOlympiaAccount) {
				return hideImportOlympiaHeader(in: &state)
			}
			return .none

		case let .loadAccountsResult(.failure(error)):
			loggerGlobal.error("Failed to load accounts: \(error)")
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

	private func hideImportOlympiaHeader(in state: inout State) -> EffectTask<Action> {
		state.shouldShowMigrateOlympiaButton = false
		return .run { _ in
			await userDefaultsClient.setHideMigrateOlympiaButtonKey(true)
		}
	}
}

// MARK: Private
extension Settings {
	private func loadP2PLinks(andAccounts loadAccounts: Bool = false) -> EffectTask<Action> {
		.run { send in
			await send(.internal(.loadedP2PLinks(
				p2pLinksClient.getP2PLinks()
			)))
			if loadAccounts {
				await send(.internal(.loadAccountsResult(
					TaskResult { try await accountsClient.getAccountsOnCurrentNetwork() }
				)))
			}
		}
	}
}
