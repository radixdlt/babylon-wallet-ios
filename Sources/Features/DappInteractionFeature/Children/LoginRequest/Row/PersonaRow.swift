import FeaturePrelude

// MARK: - PersonaRow
struct PersonaRow: Sendable, FeatureReducer {
	struct State: Sendable, Equatable, Hashable {
		let persona: OnNetwork.Persona
		var isSelected: Bool
		let lastLogin: Date?
		let numberOfSharedAccounts: UInt

		init(
			persona: OnNetwork.Persona,
			isSelected: Bool,
			lastLogin: Date?,
			numberOfSharedAccounts: UInt
		) {
			self.persona = persona
			self.isSelected = isSelected
			self.lastLogin = lastLogin
			self.numberOfSharedAccounts = numberOfSharedAccounts
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
		lastLogin: Date(),
		numberOfSharedAccounts: 2
	)
}
#endif
