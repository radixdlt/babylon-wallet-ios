import MainFeature
import OnboardingFeature
import Profile
import SplashFeature

// MARK: - App.Action
public extension App {
	// MARK: Action
	enum Action: Equatable {
		case main(Main.Action)
		case onboarding(Onboarding.Action)
		case splash(Splash.Action)

		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
	}
}

// MARK: - App.Action.CoordinatingAction
public extension App.Action {
	enum CoordinatingAction: Equatable {
		case onboard
		case toMain

		case failedToCreateOrImportProfile(reason: String)
	}

	enum InternalAction: Equatable {
		case injectProfileIntoProfileClient(Profile)
	}
}
