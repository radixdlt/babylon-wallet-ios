import ComposableArchitecture
import Profile

// MARK: - NewProfile.Action
public extension NewProfile {
	// MARK: Action
	enum Action: Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - NewProfile.Action.ViewAction
public extension NewProfile.Action {
	enum ViewAction: Equatable {
		case backButtonPressed
		case accountNameTextFieldChanged(String)
		case createProfileButtonPressed
	}
}

// MARK: - NewProfile.Action.InternalAction
public extension NewProfile.Action {
	enum InternalAction: Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - NewProfile.Action.SystemAction
public extension NewProfile.Action {
	enum SystemAction: Equatable {
		case createProfile
		case createdProfileResult(TaskResult<Profile>)
	}
}

// MARK: - NewProfile.Action.DelegateAction
public extension NewProfile.Action {
	enum DelegateAction: Equatable {
		case goBack
		case finishedCreatingNewProfile(Profile)
	}
}
