import CreateEntityFeature
import CreateProfileFeature
import FeaturePrelude

// MARK: - Onboarding.Action
public extension Onboarding {
	// MARK: Action
	enum Action: Sendable, Equatable {
		case child(ChildAction)
		case delegate(DelegateAction)
	}
}

// MARK: - Onboarding.Action.ChildAction
public extension Onboarding.Action {
	enum ChildAction: Sendable, Equatable {
		case createProfile(CreateProfileCoordinator.Action)
		case createAccountCoordinator(CreateAccountCoordinator.Action)
	}
}

// MARK: - Onboarding.Action.DelegateAction
public extension Onboarding.Action {
	enum DelegateAction: Sendable, Equatable {
		case completed
	}
}
