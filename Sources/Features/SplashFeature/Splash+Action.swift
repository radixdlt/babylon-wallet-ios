import FeaturePrelude
import LocalAuthenticationClient
import ProfileClient

// MARK: - Splash.Action
extension Splash {
	// MARK: Action
	public enum Action: Sendable, Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - Splash.Action.ViewAction
extension Splash.Action {
	public enum ViewAction: Sendable, Equatable {
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
extension Splash.Action {
	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - Splash.Action.SystemAction
extension Splash.Action {
	public enum SystemAction: Sendable, Equatable {
		case biometricsConfigResult(TaskResult<LocalAuthenticationConfig>)
		case loadProfileResult(ProfileClient.LoadProfileResult)
	}
}

// MARK: - Splash.Action.DelegateAction
extension Splash.Action {
	public enum DelegateAction: Sendable, Equatable {
		case profileResultLoaded(ProfileClient.LoadProfileResult)
	}
}
