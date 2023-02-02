import DappInteractionHookFeature
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
		public var dappInteractionHook: DappInteractionHook.State

		public init(
			home: Home.State = .init(),
			settings: AppSettings.State? = nil,
			dappInteractionHook: DappInteractionHook.State = .init()
		) {
			self.home = home
			self.settings = settings
			self.dappInteractionHook = dappInteractionHook
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
