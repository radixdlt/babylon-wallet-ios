import ComposableArchitecture
import CreateAccountFeature
import ImportProfileFeature

// MARK: - Onboarding.State
public extension Onboarding {
	// MARK: State
	enum State: Equatable {
		case importProfile(ImportProfile.State)
		case createAccountFlow(CreateAccountCoordinator.State)

		public init() {
			self = .createAccountFlow(.createAccount(.init(shouldCreateProfile: true)))
		}
	}
}

#if DEBUG
public extension Onboarding.State {
	static let previewValue: Self = .init()
}
#endif
