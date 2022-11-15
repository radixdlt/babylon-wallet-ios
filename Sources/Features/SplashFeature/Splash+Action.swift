import ComposableArchitecture
import Profile

// MARK: - Splash.Action
public extension Splash {
	// MARK: Action
	enum Action: Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - Splash.Action.ViewAction
public extension Splash.Action {
	enum ViewAction: Equatable {
		case viewAppeared
	}
}

// MARK: - Splash.Action.InternalAction
public extension Splash.Action {
	enum InternalAction: Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - Splash.Action.SystemAction
public extension Splash.Action {
	enum SystemAction: Equatable {
		case loadProfile
		case loadProfileResult(TaskResult<Profile?>)
	}
}

// MARK: - Splash.Action.DelegateAction
public extension Splash.Action {
	enum DelegateAction: Equatable {
		case profileLoaded(Profile?)
	}
}
