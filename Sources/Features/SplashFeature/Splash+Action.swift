import FeaturePrelude
import LocalAuthenticationClient
import ProfileClient

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
		public enum BiometricsCheckFailedAlertAction: Sendable, Equatable {
			case dismissed
			case cancelButtonTapped
			case openSettingsButtonTapped
		}

		case viewAppeared
		case biometricsCheckFailed(BiometricsCheckFailedAlertAction)
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
		case biometricsConfigResult(TaskResult<LocalAuthenticationConfig>)
		case loadProfileResult(ProfileClient.LoadProfileResult)
	}
}

// MARK: - Splash.Action.DelegateAction
public extension Splash.Action {
	enum DelegateAction: Sendable, Equatable {
		case profileResultLoaded(ProfileClient.LoadProfileResult)
	}
}
