import AppPreferencesClient
import FactorSourcesClient
import FeaturePrelude
import Logging

// MARK: - GeneralSettings
public struct GeneralSettings: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var preferences: AppPreferences?
		public var hasLedgerHardwareWalletFactorSources: Bool = false
		var exportLogs: URL?

		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case useVerboseModeToggled(Bool)
		case developerModeToggled(Bool)
		case exportLogsTapped
		case exportLogsDismissed
	}

	public enum InternalAction: Sendable, Equatable {
		case loadPreferences(AppPreferences)
		case hasLedgerHardwareWalletFactorSourcesLoaded(Bool)
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
}
