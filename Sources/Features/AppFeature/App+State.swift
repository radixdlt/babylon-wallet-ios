import FeaturePrelude
import MainFeature
import OnboardingFeature
import SplashFeature

// MARK: App.State
extension App {
	public struct State: Equatable {
		public enum Root: Equatable {
			case main(Main.State)
			case onboardingCoordinator(OnboardingCoordinator.State)
			case splash(Splash.State)
		}

		public var root: Root

		@PresentationState
		public var alert: Alerts.State?

		public init(root: Root = .splash(.init())) {
			self.root = root
		}
	}
}
