import CreateAccountFeature
import FeaturePrelude
import ImportProfileFeature

// MARK: - Onboarding.State
public extension Onboarding {
	// MARK: State
	enum State: Equatable {
		case importProfile(ImportProfile.State)
		case createAccountCoordinator(CreateAccountCoordinator.State)

		public init() {
			self = .createAccountCoordinator(
				.init(
					step: .step0_nameNewEntity(.init(isFirst: true)),
					config: .init(
						create: .profile
					),
					completionDestination: .home
				)
			)
		}
	}
}

#if DEBUG
public extension Onboarding.State {
	static let previewValue: Self = .init()
}
#endif
