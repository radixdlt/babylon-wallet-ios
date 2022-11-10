import EngineToolkit
import HomeFeature
import SettingsFeature

// MARK: - Main.State
public extension Main {
	// MARK: State
	struct State: Equatable {
		public var home: Home.State
		public var settings: Settings.State?

		public init(
			home: Home.State = .init(),
			settings: Settings.State? = nil
		) {
			self.home = home
			self.settings = settings
		}
	}
}

#if DEBUG
public extension Main.State {
	static let placeholder = Self(
		home: .placeholder,
		settings: nil
	)
}
#endif
