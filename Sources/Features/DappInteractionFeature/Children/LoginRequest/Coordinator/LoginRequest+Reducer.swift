import FeaturePrelude

// MARK: - LoginRequest
public struct LoginRequest: Sendable, ReducerProtocol {
	public init() {}

	@Dependency(\.profileClient) var profileClient

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
	}

	func core(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .view(.appeared):
			let personas = await profileClient.getPersonas()
			state.personas = personas

			let connectedDapps = await profileClient.getConnectedDapps()
			let connectedDapp = connectedDapps.first(where: { $0.dAppDefinitionAddress == state.dappDefinitionAddress })
			state.connectedDapp = connectedDapp

			if let connectedDapp {
				for persona in personas {
					if
						let authorizedPersona = connectedDapp.referencesToAuthorizedPersonas.first(where: { $0.identityAddress == persona.address }),
						let existingAuthorizedPersona = state.authorizedPersona,
						authorizedPersona.lastLoginDate > existingAuthorizedPersona.lastLoginDate
					{
						state.authorizedPersona = authorizedPersona
					}
				}
			}

		case let .child(.persona(id: id, action: action)):
			switch action {
			case .internal(.view(.didSelect)):
				state.personas.forEach {
					if $0.id == id {
						if !$0.isSelected {
							state.personas[id: $0.id]?.isSelected = true
						}
					} else {
						state.personas[id: $0.id]?.isSelected = false
					}
				}
				return .none
			}

		case .internal:
			return .none
		}
	}
}
