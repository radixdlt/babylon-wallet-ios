import FeaturePrelude
import GrantDappWalletAccessFeature
import HandleDappRequests
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
		public var handleDappRequests: HandleDappRequests.State

		public init(
			home: Home.State = .init(),
			handleDappRequests: HandleDappRequests.State = .init(),
			settings: AppSettings.State? = nil
		) {
			self.home = home
			self.settings = settings
			self.handleDappRequests = handleDappRequests
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
