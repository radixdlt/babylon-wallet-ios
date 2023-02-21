import FeaturePrelude

// MARK: - NewProfile.State
extension NewProfile {
	public struct State: Sendable, Hashable {
		public init() {}
	}
}

#if DEBUG
extension NewProfile.State {
	public static let previewValue: Self = .init()
}
#endif
