import CreateEntityFeature
import FeaturePrelude

// MARK: - OnboardingCoordinator.Action
extension OnboardingCoordinator {
	// MARK: Action
	public enum Action: Sendable, Equatable {
		case child(ChildAction)
		case delegate(DelegateAction)
	}
}

// MARK: - OnboardingCoordinator.Action.ChildAction
extension OnboardingCoordinator.Action {
	public enum ChildAction: Sendable, Equatable {
		case importProfile(ImportProfile.Action)
		case newProfileThenAccountCoordinator(NewProfileThenAccountCoordinator.Action)
	}
}

// MARK: - OnboardingCoordinator.Action.DelegateAction
extension OnboardingCoordinator.Action {
	public enum DelegateAction: Sendable, Equatable {
		case completed
	}
}
