import FeaturePrelude

// MARK: - PersonaRow
struct PersonaRow: Sendable, FeatureReducer {
	struct State: Sendable, Equatable, Hashable, Identifiable {
		typealias ID = IdentityAddress

		var id: ID { persona.address }
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

	enum ViewAction: Sendable, Equatable {
		case didSelect
	}

	enum DelegateAction: Sendable, Equatable {
		case didSelect
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .didSelect:
			return .send(.delegate(.didSelect))
		}
	}
}
