import CreateEntityFeature
import EditPersonaFeature
import FeaturePrelude
import PersonasClient

// MARK: - AccountPermission
struct OneTimePersonaData: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let dappMetadata: DappMetadata
		var personas: IdentifiedArrayOf<PersonaDataPermissionBox.State> = []
		var selectedPersona: PersonaDataPermissionBox.State?
		let requiredFieldIDs: Set<Profile.Network.Persona.Field.ID>

		var hasAnyPersonaOnAnyNetwork: Bool? = nil

		@PresentationState
		var destination: Destinations.State?

		init(
			dappMetadata: DappMetadata,
			requiredFieldIDs: Set<Profile.Network.Persona.Field.ID>,
			hasAnyPersonaOnAnyNetwork: Bool? = nil
		) {
			self.dappMetadata = dappMetadata
			self.requiredFieldIDs = requiredFieldIDs
			self.hasAnyPersonaOnAnyNetwork = hasAnyPersonaOnAnyNetwork
		}
	}

	enum ViewAction: Sendable, Equatable {
		case appeared
		case selectedPersonaChanged(PersonaDataPermissionBox.State?)
		case createNewPersonaButtonTapped
		case continueButtonTapped(IdentifiedArrayOf<Profile.Network.Persona.Field>)
	}

	enum InternalAction: Sendable, Equatable {
		case personasLoaded(IdentifiedArrayOf<Profile.Network.Persona>)
		case hasAnyPersonaOnAnyNetwork(Bool)
	}

	enum ChildAction: Sendable, Equatable {
		case persona(id: PersonaDataPermissionBox.State.ID, action: PersonaDataPermissionBox.Action)
		case destination(PresentationAction<Destinations.Action>)
	}

	enum DelegateAction: Sendable, Equatable {
		case continueButtonTapped(IdentifiedArrayOf<Profile.Network.Persona.Field>)
	}

	struct Destinations: Sendable, ReducerProtocol {
		enum State: Sendable, Hashable {
			case editPersona(EditPersona.State)
			case createPersona(CreatePersonaCoordinator.State)
		}

		enum Action: Sendable, Equatable {
			case editPersona(EditPersona.Action)
			case createPersona(CreatePersonaCoordinator.Action)
		}

		var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.editPersona, action: /Action.editPersona) {
				EditPersona()
			}
			Scope(state: /State.createPersona, action: /Action.createPersona) {
				CreatePersonaCoordinator()
			}
		}
	}

	@Dependency(\.personasClient) var personasClient
	@Dependency(\.errorQueue) var errorQueue

	var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.forEach(\.personas, action: /Action.child .. ChildAction.persona) {
				PersonaDataPermissionBox()
			}
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return loadPersonasEffect()

		case let .selectedPersonaChanged(persona):
			state.selectedPersona = persona
			return .none

		case .createNewPersonaButtonTapped:
			assert(state.hasAnyPersonaOnAnyNetwork != nil, "Should have checked 'hasAnyPersonaOnAnyNetwork' already")
			let isFirstOnAnyNetwork = state.hasAnyPersonaOnAnyNetwork ?? true

			state.destination = .createPersona(.init(config: .init(
				purpose: .newPersonaDuringDappInteract(isFirst: state.personas.isEmpty)
			), displayIntroduction: { _ in isFirstOnAnyNetwork }))
			return .none

		case let .continueButtonTapped(fields):
			return .send(.delegate(.continueButtonTapped(fields)))
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .hasAnyPersonaOnAnyNetwork(hasAnyPersonaOnAnyNetwork):
			state.hasAnyPersonaOnAnyNetwork = hasAnyPersonaOnAnyNetwork
			return .none

		case let .personasLoaded(personas):
			state.personas = IdentifiedArrayOf(
				uncheckedUniqueElements: personas.map {
					.init(persona: $0, requiredFieldIDs: state.requiredFieldIDs)
				}
			)
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .persona(id, .delegate(.edit)):
			if let persona = state.personas[id: id] {
				state.destination = .editPersona(.init(
					mode: .dapp(requiredFieldIDs: state.requiredFieldIDs),
					persona: persona.persona
				))
			}
			return .none

		case let .destination(.presented(.editPersona(.delegate(.personaSaved(persona))))):
			state.personas[id: persona.id] = .init(persona: persona, requiredFieldIDs: state.requiredFieldIDs)
			if state.selectedPersona?.id == persona.id {
				state.selectedPersona = .init(persona: persona, requiredFieldIDs: state.requiredFieldIDs)
			}
			return .none

		case .destination(.presented(.createPersona(.delegate(.completed)))):
			return loadPersonasEffect()

		default:
			return .none
		}
	}

	func loadPersonasEffect() -> EffectTask<Action> {
		.run { send in
			let personas = try await personasClient.getPersonas()
			await send(.internal(.personasLoaded(personas)))
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}

	func checkIfFirstPersonaByUserEver() -> EffectTask<Action> {
		.task {
			let hasAnyPersonaOnAnyNetwork = await personasClient.hasAnyPersonaOnAnyNetworks()
			return .internal(.hasAnyPersonaOnAnyNetwork(hasAnyPersonaOnAnyNetwork))
		}
	}
}
