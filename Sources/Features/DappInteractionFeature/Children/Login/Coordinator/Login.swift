import CreateEntityFeature
import FeaturePrelude

// MARK: - LoginRequest
struct Login: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var selectedPersona: OnNetwork.Persona? {
			personas.first(where: { $0.isSelected })?.persona
		}

		let dappDefinitionAddress: DappDefinitionAddress
		let dappMetadata: DappMetadata

		var personas: IdentifiedArrayOf<PersonaRow.State> = []
		var connectedDapp: OnNetwork.ConnectedDapp?
		var authorizedPersona: OnNetwork.ConnectedDapp.AuthorizedPersonaSimple?

		@PresentationState
		var createPersonaCoordinator: CreatePersonaCoordinator.State? = nil

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
		case continueButtonTapped(OnNetwork.Persona)
	}

	enum InternalAction: Sendable, Equatable {
		case personasLoaded(IdentifiedArrayOf<OnNetwork.Persona>, OnNetwork.ConnectedDapp?, OnNetwork.ConnectedDapp.AuthorizedPersonaSimple?)
	}

	enum ChildAction: Sendable, Equatable {
		case persona(id: PersonaRow.State.ID, action: PersonaRow.Action)
		case createPersonaCoordinator(PresentationActionOf<CreatePersonaCoordinator>)
	}

	enum DelegateAction: Sendable, Equatable {
		case continueButtonTapped(OnNetwork.Persona, OnNetwork.ConnectedDapp?, OnNetwork.ConnectedDapp.AuthorizedPersonaSimple?)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.profileClient) var profileClient

	var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.forEach(\.personas, action: /Action.child .. ChildAction.persona) {
				PersonaRow()
			}
			.presentationDestination(\.$createPersonaCoordinator, action: /Action.child .. ChildAction.createPersonaCoordinator) {
				CreatePersonaCoordinator()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return loadPersonas(state: &state)

		case .createNewPersonaButtonTapped:
			state.createPersonaCoordinator = .init(config: .init(
				isFirstEntity: state.personas.isEmpty,
				canBeDismissed: true,
				navigationButtonCTA: .goBackToChoosePersonas
			))
			return .none
		case let .continueButtonTapped(persona):
			return .send(.delegate(.continueButtonTapped(persona, state.connectedDapp, state.authorizedPersona)))
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .personasLoaded(personas, connectedDapp, authorizedPersonaSimple):
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
						lastLogin: lastLogin
					)
				}
				.sorted(by: { $0.isSelected && !$1.isSelected })
			)
			state.connectedDapp = connectedDapp
			state.authorizedPersona = authorizedPersonaSimple
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .persona(id: id, action: .delegate(.didSelect)):
			state.personas.forEach {
				state.personas[id: $0.id]?.isSelected = $0.id == id
			}
			return .none

		case .createPersonaCoordinator(.presented(.delegate(.dismissed))):
			state.createPersonaCoordinator = nil
			return .none

		case .createPersonaCoordinator(.presented(.delegate(.completed))):
			state.createPersonaCoordinator = nil
			return loadPersonas(state: &state)

		default:
			return .none
		}
	}

	func loadPersonas(state: inout State) -> EffectTask<Action> {
		.run { [dappDefinitionAddress = state.dappDefinitionAddress] send in
			let personas = try await profileClient.getPersonas()
			let connectedDapps = try await profileClient.getConnectedDapps()
			let connectedDapp = connectedDapps.first(by: dappDefinitionAddress)
			let authorizedPersona: OnNetwork.ConnectedDapp.AuthorizedPersonaSimple? = {
				guard let connectedDapp else {
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
			await send(.internal(.personasLoaded(personas, connectedDapp, authorizedPersona)))
		}
	}
}
