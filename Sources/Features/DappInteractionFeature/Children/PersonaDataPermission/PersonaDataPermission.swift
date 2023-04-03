import EditPersonaFeature
import FeaturePrelude
import PersonasClient

// MARK: - AccountPermission
struct PersonaDataPermission: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let dappMetadata: DappMetadata
		let personaID: Profile.Network.Persona.ID
		var persona: PersonaDataPermissionBox.State?
		let requiredFieldIDs: Set<Profile.Network.Persona.Field.ID>

		@PresentationState
		var destination: Destinations.State?

		init(
			dappMetadata: DappMetadata,
			personaID: Profile.Network.Persona.ID,
			requiredFieldIDs: Set<Profile.Network.Persona.Field.ID>
		) {
			self.dappMetadata = dappMetadata
			self.personaID = personaID
			self.requiredFieldIDs = requiredFieldIDs
		}
	}

	enum ViewAction: Sendable, Equatable {
		case appeared
		case continueButtonTapped(IdentifiedArrayOf<Profile.Network.Persona.Field>)
	}

	enum InternalAction: Sendable, Equatable {
		case personasLoaded(IdentifiedArrayOf<Profile.Network.Persona>)
	}

	enum ChildAction: Sendable, Equatable {
		case persona(PersonaDataPermissionBox.Action)
		case destination(PresentationAction<Destinations.Action>)
	}

	enum DelegateAction: Sendable, Equatable {
		case personaUpdated(Profile.Network.Persona)
		case continueButtonTapped(IdentifiedArrayOf<Profile.Network.Persona.Field>)
	}

	struct Destinations: Sendable, ReducerProtocol {
		enum State: Sendable, Hashable {
			case editPersona(EditPersona.State)
		}

		enum Action: Sendable, Equatable {
			case editPersona(EditPersona.Action)
		}

		var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.editPersona, action: /Action.editPersona) {
				EditPersona()
			}
		}
	}

	@Dependency(\.personasClient) var personasClient
	@Dependency(\.errorQueue) var errorQueue

	var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.persona, action: /Action.child .. ChildAction.persona) {
				PersonaDataPermissionBox()
			}
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .run { send in
				let personas = try await personasClient.getPersonas()
				await send(.internal(.personasLoaded(personas)))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case let .continueButtonTapped(fields):
			return .send(.delegate(.continueButtonTapped(fields)))
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .personasLoaded(personas):
			if let persona = personas[id: state.personaID] {
				state.persona = .init(persona: persona, requiredFieldIDs: state.requiredFieldIDs)
			}
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .persona(.delegate(.edit)):
			if let persona = state.persona {
				state.destination = .editPersona(.init(
					mode: .dapp(requiredFieldIDs: state.requiredFieldIDs),
					persona: persona.persona
				))
			}
			return .none

		case let .destination(.presented(.editPersona(.delegate(.personaSaved(persona))))):
			state.persona = .init(persona: persona, requiredFieldIDs: state.requiredFieldIDs)
			return .send(.delegate(.personaUpdated(persona)))

		default:
			return .none
		}
	}
}
