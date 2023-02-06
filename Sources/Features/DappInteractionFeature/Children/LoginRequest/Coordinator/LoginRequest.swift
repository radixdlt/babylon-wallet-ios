import FeaturePrelude

// MARK: - LoginRequest
struct LoginRequest: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let dappDefinitionAddress: DappDefinitionAddress
		let dappMetadata: DappMetadata

		var personas: IdentifiedArrayOf<PersonaRow.State> = []
		var authorizedPersona: OnNetwork.ConnectedDapp.AuthorizedPersonaSimple?
		var selectedPersona: OnNetwork.Persona? {
			personas.first(where: { $0.isSelected })?.persona
		}

		init(
			dappDefinitionAddress: DappDefinitionAddress,
			dappMetadata: DappMetadata
		) {
			self.dappDefinitionAddress = dappDefinitionAddress
			self.dappMetadata = dappMetadata
		}
	}

	enum ViewAction: Sendable, Equatable {
		case appeared
		case createNewPersonaButtonTapped
		case continueButtonTapped(OnNetwork.Persona, OnNetwork.ConnectedDapp.AuthorizedPersonaSimple?)
	}

	enum InternalAction: Sendable, Equatable {
		case personasLoaded(IdentifiedArrayOf<OnNetwork.Persona>, OnNetwork.ConnectedDapp.AuthorizedPersonaSimple?)
	}

	enum ChildAction: Sendable, Equatable {
		case persona(id: PersonaRow.State.ID, action: PersonaRow.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case continueButtonTapped(OnNetwork.Persona, OnNetwork.ConnectedDapp.AuthorizedPersonaSimple?)
	}

	@Dependency(\.profileClient) var profileClient

	var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.forEach(\.personas, action: /Action.child .. ChildAction.persona) {
				PersonaRow()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .run { [dappDefinitionAddress = state.dappDefinitionAddress] send in
				let personas = try await profileClient.getPersonas()
				let connectedDapps = try await profileClient.getConnectedDapps()
				let authorizedPersona: OnNetwork.ConnectedDapp.AuthorizedPersonaSimple? = {
					guard let connectedDapp = connectedDapps.first(by: dappDefinitionAddress) else {
						return nil
					}
					return personas.reduce(into: nil) { mostRecentlyAuthorizedPersona, currentPersona in
						guard let currentAuthorizedPersona = connectedDapp.referencesToAuthorizedPersonas.first(by: currentPersona.address) else {
							return
						}
						if let mostRecentlyAuthorizedPersonaCopy = mostRecentlyAuthorizedPersona {
							if currentAuthorizedPersona.lastLogin > mostRecentlyAuthorizedPersonaCopy.lastLogin {
								mostRecentlyAuthorizedPersona = currentAuthorizedPersona
							}
						} else {
							mostRecentlyAuthorizedPersona = currentAuthorizedPersona
						}
					}
				}()
				await send(.internal(.personasLoaded(personas, authorizedPersona)))
			}
		case .createNewPersonaButtonTapped:
			// TODO:
			return .none
		case let .continueButtonTapped(persona, authorizedPersona):
			return .send(.delegate(.continueButtonTapped(persona, authorizedPersona)))
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .personasLoaded(personas, authorizedPersonaSimple):
			state.personas = .init(uniqueElements:
				personas.map { (persona: OnNetwork.Persona) in
					let lastLogin: Date? = {
						guard let authorizedPersonaSimple else { return nil }
						return persona.address == authorizedPersonaSimple.identityAddress
							? authorizedPersonaSimple.lastLogin
							: nil
					}()
					return PersonaRow.State(
						persona: persona,
						isSelected: lastLogin != nil,
						lastLogin: lastLogin,
						numberOfSharedAccounts: 0 // TODO: implement
					)
				}
				.sorted(by: { $0.isSelected && !$1.isSelected })
			)
			state.authorizedPersona = authorizedPersonaSimple
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .persona(id: id, action: .delegate(.didSelect)):
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

		default:
			return .none
		}
	}
}
