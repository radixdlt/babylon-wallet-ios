import FeaturePrelude
import MainFeature
import OnboardingFeature
import ProfileClient
import SplashFeature

// MARK: - App.Action
extension App {
	// MARK: Action
	public enum Action: Sendable, Equatable {
		case child(ChildAction)
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
	}
}

// MARK: - App.Action.ChildAction
extension App.Action {
	public enum ChildAction: Sendable, Equatable {
		case main(Main.Action)
		case onboardingCoordinator(OnboardingCoordinator.Action)
		case splash(Splash.Action)
	}
}

// MARK: - App.Action.ViewAction
extension App.Action {
	public enum ViewAction: Sendable, Equatable {
		case task
		case alert(PresentationAction<App.Alerts.Action>)
	}
}

// MARK: - App.Action.InternalAction
extension App.Action {
	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - App.Action.SystemAction
extension App.Action {
	public enum SystemAction: Sendable, Equatable {
		case incompatibleProfileDeleted
		case displayErrorAlert(App.UserFacingError)
	}
}
