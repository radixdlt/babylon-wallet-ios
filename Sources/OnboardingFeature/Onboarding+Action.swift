import ComposableArchitecture
import Profile

// MARK: - Onboarding.Action
public extension Onboarding {
	// MARK: Action
	enum Action: Equatable, BindableAction {
		case binding(BindingAction<State>)
		case coordinate(CoordinatingAction)
		case `internal`(InternalAction)
	}
}

// MARK: - Onboarding.Action.CoordinatingAction
public extension Onboarding.Action {
	enum CoordinatingAction: Equatable {
		case onboardedWithProfile(Profile)
	}
}

// MARK: - Onboarding.Action.InternalAction
public extension Onboarding.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

// MARK: - Onboarding.Action.InternalAction.UserAction
public extension Onboarding.Action.InternalAction {
	enum UserAction: Equatable {
		case createProfile
	}
}

// MARK: - Onboarding.Action.InternalAction.SystemAction
public extension Onboarding.Action.InternalAction {
	enum SystemAction: Equatable {
		case createProfile
		case createdProfile(Profile)
	}
}
