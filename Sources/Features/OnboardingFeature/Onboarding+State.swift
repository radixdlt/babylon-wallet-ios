import CreateEntityFeature
import CreateProfileFeature
import FeaturePrelude

// MARK: - Onboarding.State
public extension Onboarding {
	// MARK: State
	enum State: Equatable {
		case createProfile(CreateProfileCoordinator.State)
		case createAccountCoordinator(CreateAccountCoordinator.State)

		public init() {
			self = .createProfile(.init())
		}
	}
}

#if DEBUG
public extension Onboarding.State {
	static let previewValue: Self = .init()
}
#endif
