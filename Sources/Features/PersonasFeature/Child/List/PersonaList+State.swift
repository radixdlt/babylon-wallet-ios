import FeaturePrelude

// MARK: - PersonaList.State
public extension PersonaList {
	struct State: Sendable, Equatable {
		public var personas: IdentifiedArrayOf<Persona.State>

		public init(
			personas: IdentifiedArrayOf<Persona.State> = .init()
		) {
			self.personas = personas
		}
	}
}

#if DEBUG
public extension PersonaList.State {
	static let previewValue: Self = .init()
}
#endif
