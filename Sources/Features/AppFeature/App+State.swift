import FeaturePrelude
import MainFeature
import OnboardingFeature
import SplashFeature

// MARK: App.State
public extension App {
	struct State: Equatable {
		public enum Root: Equatable {
			case main(Main.State)
			case onboarding(Onboarding.State)
			case splash(Splash.State)
		}

		public var root: Root
		public var errorAlert: AlertState<Action.ViewAction>?

		public init(
			root: Root = .splash(.init()),
			errorAlert: AlertState<Action.ViewAction>? = nil
		) {
			self.root = root
			self.errorAlert = errorAlert
		}
	}
}
