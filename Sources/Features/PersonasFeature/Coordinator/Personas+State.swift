import FeaturePrelude

// MARK: - Personas.State
public extension Personas {
	struct State: Sendable, Equatable {
		public var personas: IdentifiedArrayOf<Persona.State>

		public init(
			personas: IdentifiedArrayOf<Persona.State>
		) {
			self.personas = personas
		}
	}
}

#if DEBUG
public extension Personas.State {
	// TODO: implement
	static let previewValue: Self = .init(personas: .init())
}
#endif
