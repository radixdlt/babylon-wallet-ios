import FeaturePrelude

// MARK: - LoginRequest.State
public extension LoginRequest {
	struct State: Sendable, Hashable {
		public let dappDefinitionAddress: DappDefinitionAddress
		public let dappMetadata: DappMetadata
		public var personas: IdentifiedArrayOf<PersonaRow.State>

		public init(
			dappDefinitionAddress: DappDefinitionAddress,
			dappMetadata: DappMetadata,
//			personas: IdentifiedArrayOf<PersonaRow.State> = []
			personas: IdentifiedArrayOf<PersonaRow.State> = .init(uniqueElements: [
				.init(persona: .previewValue0),
			])
		) {
			self.dappDefinitionAddress = dappDefinitionAddress
			self.dappMetadata = dappMetadata
			self.personas = personas
		}
	}
}

#if DEBUG
public extension LoginRequest.State {
	static let previewValue: Self = .init(
		dappDefinitionAddress: try! .init(address: "account_deadbeef"),
		dappMetadata: .previewValue
	)
}
#endif
