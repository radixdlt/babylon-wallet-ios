import ComposableArchitecture
import MainFeature
import OnboardingFeature
import Profile
import SplashFeature

// MARK: - App.Action
public extension App {
	// MARK: Action
	enum Action: Equatable {
		case child(ChildAction)
		case `internal`(InternalAction)
	}
}

// MARK: - App.Action.ChildAction
public extension App.Action {
	enum ChildAction: Equatable {
		case main(Main.Action)
		case onboarding(Onboarding.Action)
		case splash(Splash.Action)
	}
}

// MARK: - App.Action.InternalAction
public extension App.Action {
	enum InternalAction: Equatable {
		case system(SystemAction)
	}
}

// MARK: - App.Action.SystemAction
public extension App.Action {
	enum SystemAction: Equatable {
		case injectProfileIntoProfileClientResult(TaskResult<Profile>)
	}
}
