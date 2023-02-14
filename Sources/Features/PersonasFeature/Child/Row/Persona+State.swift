import FeaturePrelude

// MARK: - Persona.State
extension Persona {
	public struct State: Sendable, Hashable, Identifiable {
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
extension Persona.State {
	public static let previewValue: Self = .init(persona: .previewValue0)
}
#endif
