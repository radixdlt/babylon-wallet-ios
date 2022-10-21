import ComposableArchitecture
import Profile

// MARK: - NewProfile.Action
public extension NewProfile {
	// MARK: Action
	enum Action: Equatable {
		case coordinate(CoordinatingAction)
		case `internal`(InternalAction)
	}
}

// MARK: - NewProfile.Action.CoordinatingAction
public extension NewProfile.Action {
	enum CoordinatingAction: Equatable {
		case goBack
		case finishedCreatingNewProfile(Profile)
	}
}

// MARK: - NewProfile.Action.InternalAction
public extension NewProfile.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

// MARK: - NewProfile.Action.InternalAction.UserAction
public extension NewProfile.Action.InternalAction {
	enum UserAction: Equatable {
		case goBack
		case accountNameChanged(String)
		case createProfile
	}
}

// MARK: - NewProfile.Action.InternalAction.SystemAction
public extension NewProfile.Action.InternalAction {
	enum SystemAction: Equatable {
		case createProfile
		case createdProfile(Profile)
	}
}
