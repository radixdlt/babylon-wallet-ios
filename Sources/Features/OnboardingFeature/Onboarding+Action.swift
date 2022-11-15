import ComposableArchitecture
import ImportProfileFeature
import Profile

// MARK: - Onboarding.Action
public extension Onboarding {
	// MARK: Action
	enum Action: Equatable {
		case child(ChildAction)
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - Onboarding.Action.ChildAction
public extension Onboarding.Action {
	enum ChildAction: Equatable {
		case newProfile(NewProfile.Action)
		case importProfile(ImportProfile.Action)
		case importMnemonic(ImportMnemonic.Action)
	}
}

// MARK: - Onboarding.Action.ViewAction
public extension Onboarding.Action {
	enum ViewAction: Equatable {
		case newProfileButtonTapped
		case importProfileButtonTapped
	}
}

// MARK: - Onboarding.Action.InternalAction
public extension Onboarding.Action {
	enum InternalAction: Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - Onboarding.Action.SystemAction
public extension Onboarding.Action {
	enum SystemAction: Equatable {}
}

// MARK: - Onboarding.Action.DelegateAction
public extension Onboarding.Action {
	enum DelegateAction: Equatable {
		case onboardedWithProfile(Profile)
		case failedToCreateOrImportProfile(reason: String)
	}
}
