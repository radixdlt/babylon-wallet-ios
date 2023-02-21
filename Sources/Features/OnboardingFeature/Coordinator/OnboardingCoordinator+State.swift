import CreateEntityFeature
import FeaturePrelude

// MARK: - OnboardingCoordinator.State
extension OnboardingCoordinator {
	// MARK: State
	public enum State: Equatable {
		case importProfile(ImportProfile.State)
		case newProfileThenAccountCoordinator(NewProfileThenAccountCoordinator.State)

		public init() {
			self = .newProfileThenAccountCoordinator(.init())
		}
	}
}

#if DEBUG
extension OnboardingCoordinator.State {
	public static let previewValue: Self = .init()
}
#endif
