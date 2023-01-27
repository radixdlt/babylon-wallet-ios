import FeaturePrelude

// MARK: - Personas.State
public extension Personas {
	struct State: Sendable, Equatable {
		public init() {}
	}
}

#if DEBUG
public extension Personas.State {
	static let previewValue: Self = .init()
}
#endif
