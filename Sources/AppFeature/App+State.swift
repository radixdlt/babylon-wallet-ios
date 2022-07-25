import ComposableArchitecture
import HomeFeature
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
	// Might change to an enum instead? and use SwitchStore in App.Coordinator body (alert not needed)
	struct State: Equatable {
		// Remove alert from App later on, just used in early stage for presenting errors
		public var alert: AlertState<Action>?

		public var main: Main.State?
		public var onboarding: Onboarding.State?
		public var splash: Splash.State?

		public init(
			alert: AlertState<Action>? = nil,
			splash: Splash.State? = nil,
			main: Main.State? = .init(wallet: .init(profile: .init(name: "A name"))),
			onboarding: Onboarding.State? = nil
		) {
			self.alert = alert
			self.splash = splash
			self.main = main
			self.onboarding = onboarding
		}
	}
}
