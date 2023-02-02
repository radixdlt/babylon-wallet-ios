import FeaturePrelude

// MARK: - CreateProfileCoordinator.State
public extension CreateProfileCoordinator {
	enum State: Sendable, Equatable {
		case importProfile(ImportProfile.State)
		case newProfile(NewProfile.State)
		public init() {
			self = .newProfile(.init())
		}
	}
}

#if DEBUG
public extension CreateProfileCoordinator.State {
	static let previewValue: Self = .init()
}
#endif
