import FeaturePrelude

// MARK: - CreateProfileCoordinator.Action
public extension CreateProfileCoordinator {
	enum Action: Sendable, Equatable {
		case `internal`(InternalAction)
		case child(ChildAction)
		case delegate(DelegateAction)
	}
}

public extension CreateProfileCoordinator.Action {
	static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
}

// MARK: - CreateProfileCoordinator.Action.ViewAction
public extension CreateProfileCoordinator.Action {
	enum ViewAction: Sendable, Equatable {
		case appeared
	}
}

// MARK: - CreateProfileCoordinator.Action.InternalAction
public extension CreateProfileCoordinator.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - CreateProfileCoordinator.Action.ChildAction
public extension CreateProfileCoordinator.Action {
	enum ChildAction: Sendable, Equatable {
		case importProfile(ImportProfile.Action)
		case newProfile(NewProfile.Action)
	}
}

// MARK: - CreateProfileCoordinator.Action.SystemAction
public extension CreateProfileCoordinator.Action {
	enum SystemAction: Sendable, Equatable {}
}

// MARK: - CreateProfileCoordinator.Action.DelegateAction
public extension CreateProfileCoordinator.Action {
	enum DelegateAction: Sendable, Equatable {
		case completedWithProfile
		case criticalFailureCouldNotCreateProfile
	}
}
