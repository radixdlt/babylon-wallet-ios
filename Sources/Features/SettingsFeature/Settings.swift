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

// MARK: - AccountSecurity
public struct AccountSecurity: Sendable, FeatureReducer {
	public typealias Store = StoreOf<Self>

	public init() {}

	// MARK: State

	public struct State: Sendable, Hashable {
		@PresentationState
		public var destination: Destinations.State?

		public init() {}
	}

	// MARK: Action

	public enum ViewAction: Sendable, Equatable {
		case mnemonicsButtonTapped
		case ledgerHardwareWalletsButtonTapped
		case verboseLedgerSigningButtonTapped
		case defaultDepositGuaranteeButtonTapped
		case importFromOlympiaWalletButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case mnemonics(DisplayMnemonics.State)
			case ledgerHardwareWallets(LedgerHardwareDevices.State)
//			case verboseLedgerSigning(VerboseLedgerSigning.State)
//			case defaultDepositGuarantees(DefaultDepositGuarantees.State)
			case importOlympiaWalletCoordinator(ImportOlympiaWalletCoordinator.State)
		}

		public enum Action: Sendable, Equatable {
			case mnemonics(DisplayMnemonics.Action)
			case ledgerHardwareWallets(LedgerHardwareDevices.Action)
//			case verboseLedgerSigning(VerboseLedgerSigning.Action)
//			case defaultDepositGuarantees(DefaultDepositGuarantees.Action)
			case importOlympiaWalletCoordinator(ImportOlympiaWalletCoordinator.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.mnemonics, action: /Action.mnemonics) {
				DisplayMnemonics()
			}
			Scope(state: /State.ledgerHardwareWallets, action: /Action.ledgerHardwareWallets) {
				LedgerHardwareDevices()
			}
			Scope(state: /State.importOlympiaWalletCoordinator, action: /Action.importOlympiaWalletCoordinator) {
				ImportOlympiaWalletCoordinator()
			}
		}
	}

	// MARK: Reducer

	@Dependency(\.dismiss) var dismiss

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .mnemonicsButtonTapped:
			state.destination = .mnemonics(.init())
			return .none

		case .ledgerHardwareWalletsButtonTapped:
			state.destination = .ledgerHardwareWallets(.init(context: .settings))
			return .none

		case .verboseLedgerSigningButtonTapped:
			// state.destination = .verboseLedgerSigning(.init())
			return .none

		case .defaultDepositGuaranteeButtonTapped:
			// state.destination = .defaultDepositGuarantee(.init())
			return .none

		case .importFromOlympiaWalletButtonTapped:
			state.destination = .importOlympiaWalletCoordinator(.init())
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destination(.presented(.importOlympiaWalletCoordinator(.delegate(.finishedMigration(gotoAccountList))))):
			state.destination = nil
			if gotoAccountList {
				// FIXME: Probably call delegate in order to dismiss all the way back
				return .run { _ in await dismiss() }
			}
			return .none

		case .destination:
			return .none
		}
	}
}

#if DEBUG
import DebugInspectProfileFeature
import SecurityStructureConfigurationListFeature

// MARK: - DebugSettings

public struct DebugSettings: Sendable, FeatureReducer {
	public typealias Store = StoreOf<Self>

	public init() {}

	// MARK: State

	public struct State: Sendable, Hashable {
		@PresentationState
		public var destination: Destinations.State?

		public init() {}
	}

	// MARK: Action

	public enum ViewAction: Sendable, Equatable {
		case factorSourcesButtonTapped
		case debugInspectProfileButtonTapped
		case securityStructureConfigsButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case profileToDebugLoaded(Profile)
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case debugInspectProfile(DebugInspectProfile.State)
			case debugManageFactorSources(ManageFactorSources.State)
			case securityStructureConfigs(SecurityStructureConfigurationListCoordinator.State)
		}

		public enum Action: Sendable, Equatable {
			case debugInspectProfile(DebugInspectProfile.Action)
			case debugManageFactorSources(ManageFactorSources.Action)
			case securityStructureConfigs(SecurityStructureConfigurationListCoordinator.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.debugInspectProfile, action: /Action.debugInspectProfile) {
				DebugInspectProfile()
			}
			Scope(state: /State.debugManageFactorSources, action: /Action.debugManageFactorSources) {
				ManageFactorSources()
			}
			Scope(state: /State.securityStructureConfigs, action: /Action.securityStructureConfigs) {
				SecurityStructureConfigurationListCoordinator()
					._printChanges()
			}
		}
	}

	// MARK: Reducer

	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.dismiss) var dismiss

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .factorSourcesButtonTapped:
			state.destination = .debugManageFactorSources(.init())
			return .none

		case .debugInspectProfileButtonTapped:
			return .run { send in
				let snapshot = await appPreferencesClient.extractProfileSnapshot()
				guard let profile = try? Profile(snapshot: snapshot) else { return }
				await send(.internal(.profileToDebugLoaded(profile)))
			}

		case .securityStructureConfigsButtonTapped:
			state.destination = .securityStructureConfigs(.init())
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .profileToDebugLoaded(profile):
			state.destination = .debugInspectProfile(.init(profile: profile))
			return .none
		}
	}
}
#endif
