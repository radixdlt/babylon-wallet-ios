import ComposableArchitecture
import SwiftUI

// MARK: - AppSettings
public struct AppSettings: Sendable, FeatureReducer {
	// MARK: State

	public struct State: Sendable, Hashable {
		@PresentationState
		public var destination: Destination.State?

		public var preferences: AppPreferences?
		var exportLogs: URL?

		public init() {}
	}

	// MARK: Action

	public enum ViewAction: Sendable, Equatable {
		case appeared

		case manageP2PLinksButtonTapped
		case gatewaysButtonTapped
		case profileBackupSettingsButtonTapped
		case accountAndPersonaHidingButtonTapped

		case developerModeToggled(Bool)
		case exportLogsTapped
		case exportLogsDismissed
	}

	public enum InternalAction: Sendable, Equatable {
		case loadPreferences(AppPreferences)
	}

	public enum DelegateAction: Sendable, Equatable {
		case deleteProfileAndFactorSources(keepInICloudIfPresent: Bool)
	}

	// MARK: Destination

	public struct Destination: DestinationReducer {
		public enum State: Sendable, Hashable {
			case manageP2PLinks(P2PLinksFeature.State)
			case gatewaySettings(GatewaySettings.State)
			case profileBackupSettings(ProfileBackupSettings.State)
			case accountAndPersonasHiding(AccountAndPersonaHiding.State)
		}

		public enum Action: Sendable, Equatable {
			case manageP2PLinks(P2PLinksFeature.Action)
			case gatewaySettings(GatewaySettings.Action)
			case profileBackupSettings(ProfileBackupSettings.Action)
			case accountAndPersonasHiding(AccountAndPersonaHiding.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.manageP2PLinks, action: /Action.manageP2PLinks) {
				P2PLinksFeature()
			}
			Scope(state: /State.gatewaySettings, action: /Action.gatewaySettings) {
				GatewaySettings()
			}
			Scope(state: /State.profileBackupSettings, action: /Action.profileBackupSettings) {
				ProfileBackupSettings()
			}
			Scope(state: /State.accountAndPersonasHiding, action: /Action.accountAndPersonasHiding) {
				AccountAndPersonaHiding()
			}
		}
	}

	// MARK: Reducer

	public init() {}

	@Dependency(\.appPreferencesClient) var appPreferencesClient

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

		case .profileBackupSettingsButtonTapped:
			state.destination = .profileBackupSettings(.init())
			return .none

		case .accountAndPersonaHidingButtonTapped:
			state.destination = .accountAndPersonasHiding(.init())
			return .none

		case let .developerModeToggled(isEnabled):
			state.preferences?.security.isDeveloperModeEnabled = isEnabled
			guard let preferences = state.preferences else { return .none }
			return .run { _ in
				try await appPreferencesClient.updatePreferences(preferences)
			}

		case .exportLogsTapped:
			state.exportLogs = Logger.logFilePath
			return .none

		case .exportLogsDismissed:
			state.exportLogs = nil
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadPreferences(preferences):
			state.preferences = preferences
			return .none
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .profileBackupSettings(.delegate(.deleteProfileAndFactorSources(keepInICloudIfPresent))):
			.send(.delegate(.deleteProfileAndFactorSources(keepInICloudIfPresent: keepInICloudIfPresent)))

		default:
			.none
		}
	}
}
