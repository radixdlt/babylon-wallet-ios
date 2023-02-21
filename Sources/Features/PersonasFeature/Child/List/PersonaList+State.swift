import FeaturePrelude

// MARK: - PersonaList.State
extension PersonaList {
	public struct State: Sendable, Hashable {
		public var personas: IdentifiedArrayOf<Persona.State>

		public init(
			personas: IdentifiedArrayOf<Persona.State> = .init()
		) {
			self.personas = personas
		}
	}
}

#if DEBUG
extension PersonaList.State {
	public static let previewValue: Self = .init()
}
#endif
