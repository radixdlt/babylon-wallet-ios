import FeaturePrelude

// MARK: - LoginRequest.State
public extension LoginRequest {
	struct State: Sendable, Hashable {
		public let dappDefinitionAddress: DappDefinitionAddress
		public let dappMetadata: DappMetadata
		public var personas: IdentifiedArrayOf<PersonaRow.State>
		public var isKnownDapp: Bool

		public init(
			dappDefinitionAddress: DappDefinitionAddress,
			dappMetadata: DappMetadata,
			personas: IdentifiedArrayOf<PersonaRow.State> = [],
			isKnownDapp: Bool = false
		) {
			self.dappDefinitionAddress = dappDefinitionAddress
			self.dappMetadata = dappMetadata
			self.personas = .init(
				uniqueElements: personas.sorted(by: { $0.hasAlreadyLoggedIn && !$1.hasAlreadyLoggedIn })
			)
			self.isKnownDapp = isKnownDapp
		}
	}
}

public extension LoginRequest.State {
	var selectedPersona: OnNetwork.Persona? {
		personas.first(where: { $0.isSelected })?.persona
	}
}

#if DEBUG
public extension LoginRequest.State {
	static let previewValue: Self = .init(
		dappDefinitionAddress: try! .init(address: "account_deadbeef"),
		dappMetadata: .previewValue,
		personas: .init(uniqueElements: [
			.init(persona: .previewValue0, hasAlreadyLoggedIn: false),
			.init(persona: .previewValue1, hasAlreadyLoggedIn: false),
		])
	)
}
#endif
