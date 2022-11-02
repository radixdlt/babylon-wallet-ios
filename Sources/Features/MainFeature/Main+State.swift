import BrowerExtensionsConnectivityFeature
import EngineToolkit
import HomeFeature
import SettingsFeature

// MARK: - Main
/// Namespace for MainFeature
public enum Main {}

// MARK: Main.State
public extension Main {
	// MARK: State
	struct State: Equatable {
		public var browerExtensionsConnectivity: BrowerExtensionsConnectivity.State
		public var home: Home.State
		public var settings: Settings.State?

		public init(
			browerExtensionsConnectivity: BrowerExtensionsConnectivity.State = .init(),
			home: Home.State = .init(),
			settings: Settings.State? = nil
		) {
			self.browerExtensionsConnectivity = browerExtensionsConnectivity
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
