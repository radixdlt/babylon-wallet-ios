import FeaturePrelude

// MARK: - PersonaRow.State
public extension PersonaRow {
	struct State: Sendable, Equatable {
		public init() {}
	}
}

#if DEBUG
public extension PersonaRow.State {
	static let previewValue: Self = .init()
}
#endif
