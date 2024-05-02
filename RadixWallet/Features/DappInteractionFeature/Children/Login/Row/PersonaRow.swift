import ComposableArchitecture
import SwiftUI

// MARK: - PersonaRow
enum PersonaRow {
	struct State: Sendable, Equatable, Hashable, Identifiable {
		var id: Persona.ID { persona.id }
		let persona: Persona
		let lastLogin: Date?

		init(
			persona: Persona,
			lastLogin: Date?
		) {
			self.persona = persona
			self.lastLogin = lastLogin
		}
	}
}
