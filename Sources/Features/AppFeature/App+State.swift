import ComposableArchitecture
import MainFeature
import OnboardingFeature
import SplashFeature

// MARK: App.State
public extension App {
	enum State: Equatable {
		case main(Main.State?)
		case onboarding(Onboarding.State?)
		case splash(Splash.State?)

		public init() { self = .splash(.init()) }
	}
}
