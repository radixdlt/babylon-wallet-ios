import AppPreferencesClient
import CacheClient
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
		var exportLogs: URL?

		public init() {}
	}

	// MARK: Action

	public enum ViewAction: Sendable, Equatable {
		case appeared

		case manageP2PLinksButtonTapped
		case gatewaysButtonTapped
		case backUpProfileSettingsButtonTapped

		case developerModeToggled(Bool)
		case exportLogsTapped
		case exportLogsDismissed
		case deleteProfileAndFactorSourcesButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case loadPreferences(AppPreferences)
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
			case backUpProfileSettings(BackUpProfileSettings.State)
			case deleteProfileConfirmationDialog(ConfirmationDialogState<Action.DeleteProfileConfirmationDialogAction>)
		}

		public enum Action: Sendable, Equatable {
			case manageP2PLinks(P2PLinksFeature.Action)
			case gatewaySettings(GatewaySettings.Action)
			case backUpProfileSettings(BackUpProfileSettings.Action)
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
			Scope(state: /State.backUpProfileSettings, action: /Action.backUpProfileSettings) {
				BackUpProfileSettings()
			}
		}
	}

	// MARK: Reducer

	public init() {}

	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.cacheClient) var cacheClient
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
			}

		case .manageP2PLinksButtonTapped:
			state.destination = .manageP2PLinks(.init())
			return .none

		case .gatewaysButtonTapped:
			state.destination = .gatewaySettings(.init())
			return .none

		case .backUpProfileSettingsButtonTapped:
			state.destination = .backUpProfileSettings(.init())
			return .none

		case let .developerModeToggled(isEnabled):
			state.preferences?.security.isDeveloperModeEnabled = isEnabled
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
