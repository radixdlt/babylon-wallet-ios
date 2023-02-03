import CreateEntityFeature
import FeaturePrelude

// MARK: - OnboardingCoordinator.State
public extension OnboardingCoordinator {
	// MARK: State
	enum State: Equatable {
		case importProfile(ImportProfile.State)
		case newProfileThenAccountCoordinator(NewProfileThenAccountCoordinator.State)

		public init() {
			self = .newProfileThenAccountCoordinator(.init())
		}
	}
}

#if DEBUG
public extension OnboardingCoordinator.State {
	static let previewValue: Self = .init()
}
#endif
