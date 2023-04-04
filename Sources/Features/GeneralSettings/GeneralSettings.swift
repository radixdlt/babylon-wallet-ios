import AppPreferencesClient
import FeaturePrelude

// MARK: - GeneralSettings
public struct GeneralSettings: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var preferences: AppPreferences?

		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case developerModeToggled(AppPreferences.Security.IsDeveloperModeEnabled)
	}

	public enum InternalAction: Sendable, Equatable {
		case loadPreferences(AppPreferences)
	}

	public init() {}

	@Dependency(\.appPreferencesClient) var appPreferencesClient

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .run { send in
				let preferences = await appPreferencesClient.getPreferences()
				await send(.internal(.loadPreferences(preferences)))
			}

		case let .developerModeToggled(value):
			state.preferences?.security.isDeveloperModeEnabled = value
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
		}
	}
}
