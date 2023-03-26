import FeaturePrelude

// MARK: - PersonaRow
enum PersonaRow {
	struct State: Sendable, Equatable, Hashable, Identifiable {
		var id: Profile.Network.Persona.ID { persona.id }
		let persona: Profile.Network.Persona
		let lastLogin: Date?

		init(
			persona: Profile.Network.Persona,
			lastLogin: Date?
		) {
			self.persona = persona
			self.lastLogin = lastLogin
		}
	}
}
