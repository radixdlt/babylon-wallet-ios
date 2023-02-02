import FeaturePrelude

// MARK: - PersonaRow.State
public extension PersonaRow {
	struct State: Sendable, Equatable, Hashable {
		public let persona: OnNetwork.Persona
		public var selectionState: SelectionState
		public let hasAlreadyLoggedIn: Bool

		public init(
			persona: OnNetwork.Persona,
			hasAlreadyLoggedIn: Bool
		) {
			self.persona = persona
			self.selectionState = hasAlreadyLoggedIn ? .selected : .unselected
			self.hasAlreadyLoggedIn = hasAlreadyLoggedIn
		}
	}
}

// MARK: - PersonaRow.State + Identifiable
extension PersonaRow.State: Identifiable {
	public typealias ID = IdentityAddress
	public var address: IdentityAddress { persona.address }
	public var id: ID { address }
}

// MARK: - PersonaRow.State.SelectionState
public extension PersonaRow.State {
	enum SelectionState: Sendable, Equatable {
		case unselected
		case selected
		case disabled
	}
}

#if DEBUG
public extension PersonaRow.State {
	static let previewValue: Self = .init(
		persona: .previewValue0,
		hasAlreadyLoggedIn: true
	)
}
#endif
