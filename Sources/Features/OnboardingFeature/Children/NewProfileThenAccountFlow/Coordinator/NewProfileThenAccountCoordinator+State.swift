import CreateEntityFeature
import FeaturePrelude
import ProfileClient

// MARK: - NewProfileThenAccountCoordinator.State
public extension NewProfileThenAccountCoordinator {
	struct State: Sendable, Hashable {
		public enum Step: Sendable, Hashable {
			case newProfile(NewProfile.State)
			case createAccountCoordinator(CreateAccountCoordinator.State)
		}

		public var step: Step
		public var unsavedProfile: CreateEphemeralProfileAndUnsavedOnDeviceFactorSourceResponse?

		public init(
			step: Step = .newProfile(.init()),
			unsavedProfile: CreateEphemeralProfileAndUnsavedOnDeviceFactorSourceResponse? = nil
		) {
			self.step = step
			self.unsavedProfile = unsavedProfile
		}
	}
}

#if DEBUG
public extension NewProfileThenAccountCoordinator.State {
	static let previewValue: Self = .init()
}
#endif
