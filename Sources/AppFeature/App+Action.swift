import MainFeature
import OnboardingFeature
import SplashFeature
import Wallet

public extension App {
	// MARK: Action
	enum Action: Equatable {
		case main(Main.Action)
		case onboarding(Onboarding.Action)
		case splash(Splash.Action)

		case coordinate(CoordinatingAction)
	}
}

public extension App.Action {
	enum CoordinatingAction: Equatable {
		case onboard
		case toMain(Wallet)
	}
}
