import FeaturePrelude

// MARK: - LoginRequest.State
public extension LoginRequest {
	struct State: Sendable, Hashable {
		let dappDefinitionAddress: DappDefinitionAddress
		let dappMetadata: DappMetadata
		var personas: IdentifiedArrayOf<PersonaRow.State>
		var connectedDapp: OnNetwork.ConnectedDapp?
		var mostRecentPersona: OnNetwork.ConnectedDapp.AuthorizedPersonaSimple?

		public init(
			dappDefinitionAddress: DappDefinitionAddress,
			dappMetadata: DappMetadata
		) {
			self.dappDefinitionAddress = dappDefinitionAddress
			self.dappMetadata = dappMetadata
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
