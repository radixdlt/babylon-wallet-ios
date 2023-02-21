import FeaturePrelude
import HomeFeature
import P2PConnectivityClient
import SettingsFeature
import TransactionSigningFeature

// MARK: - Main.State
extension Main {
	// MARK: State
	public struct State: Equatable {
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
extension Main.State {
	public static let previewValue = Self(
		home: .previewValue,
		settings: nil
	)
}
#endif
