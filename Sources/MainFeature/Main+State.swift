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
		public var networkID: NetworkID
		public var home: Home.State
		public var settings: Settings.State?

		internal init(
			networkID: NetworkID,
			home: Home.State,
			settings: Settings.State? = nil
		) {
			precondition(home.networkID == networkID)
			self.networkID = networkID
			self.home = home
			self.settings = settings
		}

		public init(
			networkID: NetworkID
		) {
			self.init(
				networkID: networkID,
				home: .init(networkID: networkID),
				settings: nil
			)
		}
	}
}

#if DEBUG
public extension Main.State {
	static let placeholder = Self(
		networkID: .primary,
		home: .placeholder,
		settings: nil
	)
}
#endif
