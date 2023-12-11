import ComposableArchitecture
import SwiftUI

extension Settings.Destination.State {
	static func displayMnemonics() -> Self {
		.accountSecurity(AccountSecurity.State(destination: .mnemonics(.init())))
	}
}

// MARK: - Settings
public struct Settings: Sendable, FeatureReducer {
	public typealias Store = StoreOf<Self>

	public init() {}

	// MARK: State

	public struct State: Sendable, Hashable {
		@PresentationState
		public var destination: Destination.State?

		public var shouldShowMigrateOlympiaButton: Bool = false
		public var userHasNoP2PLinks: Bool? = nil
		public var shouldWriteDownPersonasSeedPhrase: Bool = false

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
		case loadedShouldWriteDownPersonasSeedPhrase(Bool)
	}

	public enum DelegateAction: Sendable, Equatable {
		case deleteProfileAndFactorSources(keepInICloudIfPresent: Bool)
	}

	public struct Destination: DestinationReducer {
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
	@Dependency(\.userDefaults) var userDefaults

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return loadP2PLinks()
				.merge(with: loadShouldShowImportWalletShortcutInSettings())
				.merge(with: loadShouldWriteDownPersonasSeedPhrase())

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

		case let .loadedShouldWriteDownPersonasSeedPhrase(shouldBackup):
			state.shouldWriteDownPersonasSeedPhrase = shouldBackup
			return .none
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .accountSecurity(.delegate(.deleteProfileAndFactorSources(keepInICloudIfPresent))):
			.send(.delegate(.deleteProfileAndFactorSources(keepInICloudIfPresent: keepInICloudIfPresent)))
		case .accountSecurity(.delegate(.gotoAccountList)):
			.run { _ in await dismiss() }
		default:
			.none
		}
	}

	public func reduceDismissedDestination(into state: inout State) -> Effect<Action> {
		switch state.destination {
		case .manageP2PLinks:
			loadP2PLinks()
		default:
			.none
		}
	}

	private func hideImportOlympiaHeader(in state: inout State) -> Effect<Action> {
		state.shouldShowMigrateOlympiaButton = false
		userDefaults.setHideMigrateOlympiaButton(true)
		return .none
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

	private func loadShouldWriteDownPersonasSeedPhrase() -> Effect<Action> {
		.run { send in
			@Dependency(\.personasClient) var personasClient
			let shouldBackup = try await personasClient.shouldWriteDownSeedPhraseForSomePersona()
			await send(.internal(.loadedShouldWriteDownPersonasSeedPhrase(shouldBackup)))
		}
	}
}
