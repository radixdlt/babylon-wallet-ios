import FeaturePrelude
import SettingsFeature

extension Main {
	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case settings(AppSettings.State)
		}

		public enum Action: Sendable, Equatable {
			case settings(AppSettings.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.settings, action: /Action.settings) {
				AppSettings()
			}
		}
	}
}
