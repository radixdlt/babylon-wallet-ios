import FeaturePrelude

// MARK: - Persona.State
public extension Persona {
	struct State: Sendable, Equatable, Identifiable {
		public typealias ID = OnNetwork.Persona.ID
		public var id: ID { persona.id }
		public let persona: OnNetwork.Persona

		public init(
			persona: OnNetwork.Persona
		) {
			self.persona = persona
		}
	}
}

#if DEBUG
public extension Persona.State {
	static let previewValue: Self = .init(persona: .previewValue0)
}
#endif
