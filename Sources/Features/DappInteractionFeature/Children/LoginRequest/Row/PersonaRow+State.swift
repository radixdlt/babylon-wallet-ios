import FeaturePrelude

// MARK: - PersonaRow.State
extension PersonaRow {
	struct State: Sendable, Equatable, Hashable {
		let persona: OnNetwork.Persona
		var isSelected: Bool
		let lastLogin: Date?

		init(
			persona: OnNetwork.Persona,
			isSelected: Bool,
			lastLogin: Date?
		) {
			self.persona = persona
			self.isSelected = isSelected
			self.lastLogin = lastLogin
		}
	}
}

// MARK: - PersonaRow.State + Identifiable
extension PersonaRow.State: Identifiable {
	typealias ID = IdentityAddress
	var address: IdentityAddress { persona.address }
	var id: ID { address }
}

#if DEBUG
extension PersonaRow.State {
	static let previewValue: Self = .init(
		persona: .previewValue0,
		isSelected: true,
		lastLogin: nil
	)
}
#endif
