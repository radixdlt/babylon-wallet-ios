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

		@PresentationState
		public var destination: Destinations.State?

		public init(home: Home.State = .init()) {
			self.home = home
		}
	}
}

#if DEBUG
extension Main.State {
	public static let previewValue = Self(home: .previewValue)
}
#endif
