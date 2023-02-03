import FeaturePrelude
import HomeFeature
import P2PConnectivityClient
import SettingsFeature
import TransactionSigningFeature

// MARK: - Main.State
public extension Main {
	// MARK: State
	struct State: Equatable {
		public var home: Home.State
		public var settings: AppSettings.State?

		public init(
			home: Home.State = .init(),
			settings: AppSettings.State? = nil
		) {
			self.home = home
			self.settings = settings
		}
	}
}

#if DEBUG
public extension Main.State {
	static let previewValue = Self(
		home: .previewValue,
		settings: nil
	)
}
#endif
