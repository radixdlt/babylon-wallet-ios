import FeaturePrelude

// MARK: - PersonaRow.State
public extension PersonaRow {
	struct State: Sendable, Equatable, Hashable {
		public let persona: OnNetwork.Persona
		public var isSelected: Bool
		public let lastLoginDate: Date?

		public init(
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
	public typealias ID = IdentityAddress
	public var address: IdentityAddress { persona.address }
	public var id: ID { address }
}

#if DEBUG
public extension PersonaRow.State {
	static let previewValue: Self = .init(
		persona: .previewValue0,
		isSelected: true,
		lastLoginDate: nil
	)
}
#endif
