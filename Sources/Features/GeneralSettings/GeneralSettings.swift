import AppPreferencesClient
import FactorSourcesClient
import FeaturePrelude

// MARK: - GeneralSettings
public struct GeneralSettings: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var preferences: AppPreferences?
		public var hasLedgerHardwareWalletFactorSources: Bool = false
		@PresentationState
		public var alert: Alerts.State?

		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case useVerboseModeToggled(Bool)
		case developerModeToggled(Bool)
		case cloudProfileSyncToggled(Bool)
		case alert(PresentationAction<Alerts.Action>)
	}

	public enum InternalAction: Sendable, Equatable {
		case loadPreferences(AppPreferences)
		case hasLedgerHardwareWalletFactorSourcesLoaded(Bool)
	}

	public struct Alerts: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case confirmCloudSyncDisable(AlertState<Action.ConfirmCloudSyncDisable>)
		}

		public enum Action: Sendable, Equatable {
			case confirmCloudSyncDisable(ConfirmCloudSyncDisable)

			public enum ConfirmCloudSyncDisable: Sendable, Hashable {
				case confirm
			}
		}

		public var body: some ReducerProtocolOf<Self> {
			EmptyReducer()
		}
	}

	public init() {}

	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .run { send in
				let preferences = await appPreferencesClient.getPreferences()
				await send(.internal(.loadPreferences(preferences)))

				do {
					let ledgers = try await factorSourcesClient.getFactorSources(ofKind: .ledgerHQHardwareWallet)
					await send(.internal(.hasLedgerHardwareWalletFactorSourcesLoaded(!ledgers.isEmpty)))
				} catch {
					loggerGlobal.warning("Failed to load ledgers, error: \(error)")
					// OK to display it...
					await send(.internal(.hasLedgerHardwareWalletFactorSourcesLoaded(true)))
				}
			}

		case let .cloudProfileSyncToggled(isEnabled):
			if !isEnabled {
				state.alert = .confirmCloudSyncDisable(.init(
					title: {
						TextState("Disabling iCloud sync will delete the iCloud backup data, are you sure you want to disable iCloud sync?")
					},
					actions: {
						ButtonState(role: .destructive, action: .confirm) {
							TextState("Confirm")
						}
					}
				))
				return .none
			} else {
				return updateCloudSync(state: &state, isEnabled: true)
			}

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
		case .alert(.presented(.confirmCloudSyncDisable(.confirm))):
			state.alert = nil
			return updateCloudSync(state: &state, isEnabled: false)
		case .alert(.dismiss):
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

	private func updateCloudSync(state: inout State, isEnabled: Bool) -> EffectTask<Action> {
		state.preferences?.security.isCloudProfileSyncEnabled = isEnabled
		return .fireAndForget {
			try await appPreferencesClient.setIsCloudProfileSyncEnabled(false)
		}
	}
}
