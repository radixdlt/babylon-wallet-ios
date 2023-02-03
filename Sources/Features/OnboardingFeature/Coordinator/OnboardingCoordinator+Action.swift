import CreateEntityFeature
import FeaturePrelude

// MARK: - OnboardingCoordinator.Action
public extension OnboardingCoordinator {
	// MARK: Action
	enum Action: Sendable, Equatable {
		case child(ChildAction)
		case delegate(DelegateAction)
	}
}

// MARK: - OnboardingCoordinator.Action.ChildAction
public extension OnboardingCoordinator.Action {
	enum ChildAction: Sendable, Equatable {
		case importProfile(ImportProfile.Action)
		case newProfileThenAccountCoordinator(NewProfileThenAccountCoordinator.Action)
	}
}

// MARK: - OnboardingCoordinator.Action.DelegateAction
public extension OnboardingCoordinator.Action {
	enum DelegateAction: Sendable, Equatable {
		case completed
	}
}
