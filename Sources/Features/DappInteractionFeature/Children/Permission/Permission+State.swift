import FeaturePrelude

// MARK: - Permission.State
public extension Permission {
	struct State: Sendable, Hashable {
		public init() {}
	}
}

#if DEBUG
public extension Permission.State {
	static let previewValue: Self = .init()
}
#endif
