//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-07-01.
//

import ComposableArchitecture
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
		case `internal`(InternalAction)
	}
}

public extension App.Action {
	enum CoordinatingAction: Equatable {
		case onboard
		case toMain(Wallet)
	}
}

public extension App.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
	}
}

public extension App.Action.InternalAction {
	enum UserAction: Equatable {
		case alertDismissed
	}
}
