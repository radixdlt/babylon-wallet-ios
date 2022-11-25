import ComposableArchitecture
import Profile

// MARK: - NewProfile.Action
public extension NewProfile {
	// MARK: Action
	enum Action: Sendable, Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - NewProfile.Action.ViewAction
public extension NewProfile.Action {
	enum ViewAction: Sendable, Equatable {
		case backButtonPressed
		case accountNameTextFieldChanged(String)
		case createProfileButtonPressed
	}
}

// MARK: - NewProfile.Action.InternalAction
public extension NewProfile.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - NewProfile.Action.SystemAction
public extension NewProfile.Action {
	enum SystemAction: Sendable, Equatable {
		case createProfile
		case createdProfileResult(TaskResult<Profile>)
	}
}

// MARK: - NewProfile.Action.DelegateAction
public extension NewProfile.Action {
	enum DelegateAction: Sendable, Equatable {
		case goBack
		case finishedCreatingNewProfile(Profile)
	}
}
