import AppPreferencesClient
import CacheClient
import FactorSourcesClient
import FeaturePrelude
import GatewaySettingsFeature
import Logging
import P2PLinksFeature
import ProfileBackupsFeature
import RadixConnectClient

// MARK: - AppSettings
public struct AppSettings: Sendable, FeatureReducer {
	// MARK: State

	public struct State: Sendable, Hashable {
		@PresentationState
		public var destination: Destinations.State?

		public var preferences: AppPreferences?
		public var hasLedgerHardwareWalletFactorSources: Bool = false
		var exportLogs: URL?

		public init() {}
	}

	// MARK: Action

	public enum ViewAction: Sendable, Equatable {
		case appeared

		case manageP2PLinksButtonTapped
		case gatewaysButtonTapped
		case profileBackupsButtonTapped

		case useVerboseModeToggled(Bool)
		case developerModeToggled(Bool)
		case exportLogsTapped
		case exportLogsDismissed
		case deleteProfileAndFactorSourcesButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case loadPreferences(AppPreferences)
		case hasLedgerHardwareWalletFactorSourcesLoaded(Bool)
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case deleteProfileAndFactorSources(keepInICloudIfPresent: Bool)
	}

	// MARK: Destinations

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case manageP2PLinks(P2PLinksFeature.State)
			case gatewaySettings(GatewaySettings.State)
			case profileBackups(ProfileBackups.State)
			case deleteProfileConfirmationDialog(ConfirmationDialogState<Action.DeleteProfileConfirmationDialogAction>)
		}

		public enum Action: Sendable, Equatable {
			case manageP2PLinks(P2PLinksFeature.Action)
			case gatewaySettings(GatewaySettings.Action)
			case profileBackups(ProfileBackups.Action)
			case deleteProfileConfirmationDialog(DeleteProfileConfirmationDialogAction)

			public enum DeleteProfileConfirmationDialogAction: Sendable, Hashable {
				case deleteProfile
				case deleteProfileLocalKeepInICloudIfPresent
				case cancel
			}
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.manageP2PLinks, action: /Action.manageP2PLinks) {
				P2PLinksFeature()
			}
			Scope(state: /State.gatewaySettings, action: /Action.gatewaySettings) {
				GatewaySettings()
			}
			Scope(state: /State.profileBackups, action: /Action.profileBackups) {
				ProfileBackups()
			}
		}
	}

	// MARK: Reducer

	public init() {}

	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.cacheClient) var cacheClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.radixConnectClient) var radixConnectClient

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .run { send in
				let preferences = await appPreferencesClient.getPreferences()
				await send(.internal(.loadPreferences(preferences)))

				do {
					let ledgers = try await factorSourcesClient.getFactorSources(type: LedgerHardwareWalletFactorSource.self)
					await send(.internal(.hasLedgerHardwareWalletFactorSourcesLoaded(!ledgers.isEmpty)))
				} catch {
					loggerGlobal.warning("Failed to load ledgers, error: \(error)")
					// OK to display it...
					await send(.internal(.hasLedgerHardwareWalletFactorSourcesLoaded(true)))
				}
			}

		case .manageP2PLinksButtonTapped:
			state.destination = .manageP2PLinks(.init())
			return .none

		case .gatewaysButtonTapped:
			state.destination = .gatewaySettings(.init())
			return .none

		case .profileBackupsButtonTapped:
			state.destination = .profileBackups(.init(context: .settings))
			return .none

		case let .developerModeToggled(isEnabled):
			state.preferences?.security.isDeveloperModeEnabled = isEnabled
			guard let preferences = state.preferences else { return .none }
			return .fireAndForget {
				try await appPreferencesClient.updatePreferences(preferences)
			}

		case let .useVerboseModeToggled(useVerboseMode):
			state.preferences?.display.ledgerHQHardwareWalletSigningDisplayMode = useVerboseMode ? .verbose : .summary
			guard let preferences = state.preferences else { return .none }
			return .fireAndForget {
				try await appPreferencesClient.updatePreferences(preferences)
			}

		case .exportLogsTapped:
			state.exportLogs = Logger.logFilePath
			return .none

		case .exportLogsDismissed:
			state.exportLogs = nil
			return .none

		case .deleteProfileAndFactorSourcesButtonTapped:
			state.destination = .deleteProfileConfirmationDialog(.deleteProfileConfirmationDialog)
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadPreferences(preferences):
			state.preferences = preferences
			return .none

		case let .hasLedgerHardwareWalletFactorSourcesLoaded(hasLedgerHardwareWalletFactorSources):
			state.hasLedgerHardwareWalletFactorSources = hasLedgerHardwareWalletFactorSources
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destination(.presented(.deleteProfileConfirmationDialog(confirmationAction))):
			switch confirmationAction {
			case .deleteProfile:
				return deleteProfile(keepInICloudIfPresent: false)

			case .deleteProfileLocalKeepInICloudIfPresent:
				return deleteProfile(keepInICloudIfPresent: true)

			case .cancel:
				return .none
			}

		case .destination:
			return .none
		}
	}

	private func deleteProfile(keepInICloudIfPresent: Bool) -> EffectTask<Action> {
		.task {
			cacheClient.removeAll()
			await radixConnectClient.disconnectAndRemoveAll()
			return .delegate(.deleteProfileAndFactorSources(keepInICloudIfPresent: keepInICloudIfPresent))
		}
	}
}

extension ConfirmationDialogState<AppSettings.Destinations.Action.DeleteProfileConfirmationDialogAction> {
	static let deleteProfileConfirmationDialog = ConfirmationDialogState {
		TextState(L10n.AppSettings.ResetWalletDialog.title)
	} actions: {
		ButtonState(role: .destructive, action: .deleteProfileLocalKeepInICloudIfPresent) {
			TextState(L10n.AppSettings.ResetWalletDialog.resetButtonTitle)
		}
		ButtonState(role: .destructive, action: .deleteProfile) {
			TextState(L10n.AppSettings.ResetWalletDialog.resetAndDeleteBackupButtonTitle)
		}
		ButtonState(role: .cancel, action: .cancel) {
			TextState(L10n.Common.cancel)
		}
	} message: {
		TextState(L10n.AppSettings.ResetWalletDialog.message)
	}
}
