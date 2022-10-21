import Foundation
import Profile

// MARK: - Settings
/// Namespace for SettingsFeature
public enum Settings {}

// MARK: Settings.State
public extension Settings {
	// MARK: State
	struct State: Equatable {
		#if DEBUG
		public var profileToInspect: Profile?
		#endif // DEBUG

		public init() {}
	}
}
