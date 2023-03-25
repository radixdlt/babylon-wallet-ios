import EditPersonaFeature
import FeaturePrelude

// MARK: - AccountPermission
struct PersonaDataPermission: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let dappMetadata: DappMetadata
		var persona: PersonaDataPermissionBox.State
		let requiredFieldIDs: Set<Profile.Network.Persona.Field.ID>

		@PresentationState
		var destination: Destinations.State?

		init(
			dappMetadata: DappMetadata,
			persona: Profile.Network.Persona,
			requiredFieldIDs: Set<Profile.Network.Persona.Field.ID>
		) {
			self.dappMetadata = dappMetadata
			self.persona = .init(persona: persona, requiredFieldIDs: requiredFieldIDs)
			self.requiredFieldIDs = requiredFieldIDs
		}
	}

	enum ViewAction: Sendable, Equatable {
		case continueButtonTapped(IdentifiedArrayOf<Profile.Network.Persona.Field>)
	}

	enum ChildAction: Sendable, Equatable {
		case persona(PersonaDataPermissionBox.Action)
		case destination(PresentationAction<Destinations.Action>)
	}

	enum DelegateAction: Sendable, Equatable {
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
		case .persona(.delegate(.edit)):
			state.destination = .editPersona(.init(
				mode: .dapp(requiredFieldIDs: state.requiredFieldIDs),
				persona: state.persona.persona
			))
			return .none

		default:
			return .none
		}
	}
}
