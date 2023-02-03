import CreateEntityFeature
import FeaturePrelude
import Profile
import ProfileModels

// MARK: - NewProfileThenAccountCoordinator.Action
public extension NewProfileThenAccountCoordinator {
	enum ViewAction: Sendable, Equatable {
		case appeared
	}

	enum DelegateAction: Sendable, Equatable {
		case criticialErrorFailedToCommitEphemeralProfile
		case completed
	}

	enum ChildAction: Sendable, Equatable {
		case newProfile(NewProfile.Action)
		case createAccountCoordinator(CreateAccountCoordinator.Action)
	}

	enum InternalAction: Sendable, Equatable {
		case commitEphemeralProfileAndPersistOnDeviceFactorSourceMnemonicResult(TaskResult<EquatableVoid>)
	}
}
