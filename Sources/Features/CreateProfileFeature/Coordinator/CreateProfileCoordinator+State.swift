import FeaturePrelude

// MARK: - CreateProfileCoordinator.State
public extension CreateProfileCoordinator {
	struct State: Sendable, Equatable {
		public init() {}
	}
}

#if DEBUG
public extension CreateProfileCoordinator.State {
	static let previewValue: Self = .init()
}
#endif
