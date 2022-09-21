import ComposableArchitecture
import MainFeature
import OnboardingFeature
import SplashFeature

// MARK: - App
/// Namespace for AppFeature
public enum App {}

public extension App {
	enum State: Equatable {
		case main(Main.State?)
		case onboarding(Onboarding.State?)
		case splash(Splash.State?)

		public init() { self = .splash(.init()) }
	}
}
