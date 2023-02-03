import FeaturePrelude

// MARK: - NewProfile.State
public extension NewProfile {
	struct State: Sendable, Hashable {
		public init() {}
	}
}

#if DEBUG
public extension NewProfile.State {
	static let previewValue: Self = .init()
}
#endif
