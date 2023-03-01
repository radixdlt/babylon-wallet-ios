import CreateEntityFeature
import FeaturePrelude
import ProfileClient

// MARK: - NewProfileThenAccountCoordinator.State
extension NewProfileThenAccountCoordinator {
	public struct State: Sendable, Hashable {
		public enum Step: Sendable, Hashable {
			case newProfile(NewProfile.State)
			case createAccountCoordinator(CreateAccountCoordinator.State)
		}

		public var step: Step
		public var ephemeralPrivateProfile: Profile.Ephemeral.Private?

		public init(
			step: Step = .newProfile(.init()),
			ephemeralPrivateProfile: Profile.Ephemeral.Private? = nil
		) {
			self.step = step
			self.ephemeralPrivateProfile = ephemeralPrivateProfile
		}
	}
}

#if DEBUG
extension NewProfileThenAccountCoordinator.State {
	public static let previewValue: Self = .init()
}
#endif
