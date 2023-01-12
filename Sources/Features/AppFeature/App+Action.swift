import FeaturePrelude
import MainFeature
import OnboardingFeature
import Profile
import SplashFeature

// MARK: - App.Action
public extension App {
	// MARK: Action
	enum Action: Sendable, Equatable {
		case child(ChildAction)
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
	}
}

// MARK: - App.Action.ChildAction
public extension App.Action {
	enum ChildAction: Sendable, Equatable {
		case main(Main.Action)
		case onboarding(Onboarding.Action)
		case splash(Splash.Action)
	}
}

// MARK: - App.Action.ViewAction
public extension App.Action {
	enum ViewAction: Sendable, Equatable {
		case task
		case errorAlertDismissButtonTapped
		case deleteIncompatibleProfile
	}
}

// MARK: - App.Action.InternalAction
public extension App.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - App.Action.SystemAction
public extension App.Action {
	enum SystemAction: Sendable, Equatable {
		case deletedIncompatibleProfile
		case displayErrorAlert(App.UserFacingError)
		case injectProfileIntoProfileClientResult(TaskResult<Profile>)
	}
}
