import CreateEntityFeature
import FeaturePrelude
import Profile

// MARK: - NewProfileThenAccountCoordinator.Action
extension NewProfileThenAccountCoordinator {
	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum DelegateAction: Sendable, Equatable {
		case criticialErrorFailedToCommitEphemeralProfile
		case completed
	}

	public enum ChildAction: Sendable, Equatable {
		case newProfile(NewProfile.Action)
		case createAccountCoordinator(CreateAccountCoordinator.Action)
	}

	public enum InternalAction: Sendable, Equatable {
		case commitEphemeralPrivateProfile(TaskResult<EquatableVoid>)
	}
}
