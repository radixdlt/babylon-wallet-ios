import EditPersonaFeature
import FeaturePrelude

// MARK: - AccountPermission
struct OneTimePersonaData: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let dappMetadata: DappMetadata
		var personas: IdentifiedArrayOf<PersonaDataPermissionBox.State> = []
		let requiredFieldIDs: Set<Profile.Network.Persona.Field.ID>

		@PresentationState
		var destination: Destinations.State?

		init(
			dappMetadata: DappMetadata,
			requiredFieldIDs: Set<Profile.Network.Persona.Field.ID>
		) {
			self.dappMetadata = dappMetadata
			self.requiredFieldIDs = requiredFieldIDs
		}
	}

	enum ViewAction: Sendable, Equatable {
		case continueButtonTapped(IdentifiedArrayOf<Profile.Network.Persona.Field>)
	}

	enum ChildAction: Sendable, Equatable {
		case persona(id: PersonaDataPermissionBox.State.ID, action: PersonaDataPermissionBox.Action)
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
		case let .continueButtonTapped(fields):
			return .send(.delegate(.continueButtonTapped(fields)))
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
			return .send(.delegate(.personaUpdated(persona)))

		default:
			return .none
		}
	}
}
