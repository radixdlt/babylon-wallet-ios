import FeaturePrelude

// MARK: - PersonaRow.State
extension PersonaRow {
	struct State: Sendable, Equatable, Hashable {
		let persona: OnNetwork.Persona
		var isSelected: Bool
		let lastLoginDate: Date?

		init(
			persona: OnNetwork.Persona,
			isSelected: Bool,
			lastLoginDate: Date?
		) {
			self.persona = persona
			self.isSelected = isSelected
			self.lastLoginDate = lastLoginDate
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
		lastLoginDate: nil
	)
}
#endif
