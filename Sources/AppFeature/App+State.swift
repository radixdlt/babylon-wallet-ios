import ComposableArchitecture
import MainFeature
import OnboardingFeature
import ProfileLoader
import SplashFeature
import UserDefaultsClient
import Wallet
import WalletLoader

// MARK: - App
/// Namespace for AppFeature
public enum App {}

public extension App {
	// MARK: State
	struct State: Equatable {
		// Remove alert from App later on, just used in early stage for presenting errors
		public var alert: AlertState<Action>?

		public var main: Main.State?
		public var onboarding: Onboarding.State?
		public var splash: Splash.State?

		public init(
			alert: AlertState<Action>? = nil,
			splash: Splash.State? = .init(),
			main: Main.State? = nil,
			onboarding: Onboarding.State? = nil
		) {
			self.alert = alert
			self.splash = splash
			self.main = main
			self.onboarding = onboarding
		}
	}
}
