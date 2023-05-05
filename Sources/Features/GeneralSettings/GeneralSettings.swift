import AppPreferencesClient
import FactorSourcesClient
import FeaturePrelude

// MARK: - GeneralSettings
public struct GeneralSettings: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var preferences: AppPreferences?
		public var hasLedgerHardwareWalletFactorSources: Bool = false
		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case useVerboseModeToggled(Bool)
		case developerModeToggled(Bool)
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
					// ok to display it...
					await send(.internal(.hasLedgerHardwareWalletFactorSourcesLoaded(true)))
				}
			}

		case let .developerModeToggled(value):
			state.preferences?.security.isDeveloperModeEnabled = value
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
