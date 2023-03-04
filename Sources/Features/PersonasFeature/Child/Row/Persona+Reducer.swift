import FeaturePrelude

// MARK: - Persona
public struct Persona: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public var id: OnNetwork.Persona.ID { persona.id }
		public let persona: OnNetwork.Persona

		public init(persona: OnNetwork.Persona) {
			self.persona = persona
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public init() {}
}
