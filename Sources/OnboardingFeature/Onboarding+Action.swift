import ComposableArchitecture
import ImportProfileFeature
import Profile

// MARK: - Onboarding.Action
public extension Onboarding {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)

		case newProfile(NewProfile.Action)
		case importProfile(ImportProfile.Action)
	}
}

// MARK: - Onboarding.Action.CoordinatingAction
public extension Onboarding.Action {
	enum CoordinatingAction: Equatable {
		case onboardedWithProfile(Profile, isNew: Bool)
		case failedToCreateOrImportProfile(reason: String)
	}
}

// MARK: - Onboarding.Action.InternalAction
public extension Onboarding.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
	}
}

// MARK: - Onboarding.Action.InternalAction.UserAction
public extension Onboarding.Action.InternalAction {
	enum UserAction: Equatable {
		case newProfile
		case importProfile
	}
}
