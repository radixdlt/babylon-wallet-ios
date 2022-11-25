import ComposableArchitecture
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
		case loadProfile
		case loadProfileResult(TaskResult<ProfileLoader.Result>)
	}
}

// MARK: - Splash.Action.DelegateAction
public extension Splash.Action {
	enum DelegateAction: Sendable, Equatable {
		case profileResultLoaded(ProfileLoader.Result)
	}
}
