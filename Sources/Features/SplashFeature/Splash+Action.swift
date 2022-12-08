import ComposableArchitecture
import LocalAuthenticationClient
import Profile
import ProfileLoader

// MARK: - Splash.Action
public extension Splash {
	// MARK: Action
	enum Action: Sendable, Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - Splash.Action.ViewAction
public extension Splash.Action {
	enum ViewAction: Sendable, Equatable {
		case viewAppeared
		case alertRetryButtonTapped
	}
}

// MARK: - Splash.Action.InternalAction
public extension Splash.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - Splash.Action.SystemAction
public extension Splash.Action {
	enum SystemAction: Sendable, Equatable {
		case verifyBiometrics
		case biometricsConfigResult(TaskResult<LocalAuthenticationConfig>)
		case loadProfile
		case loadProfileResult(ProfileLoader.ProfileResult)
	}
}

// MARK: - Splash.Action.DelegateAction
public extension Splash.Action {
	enum DelegateAction: Sendable, Equatable {
		case profileResultLoaded(ProfileLoader.ProfileResult)
	}
}
