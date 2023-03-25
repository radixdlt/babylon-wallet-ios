import EditPersonaFeature
import FeaturePrelude
import PersonasClient

// MARK: - AccountPermission
struct PersonaDataPermission: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
//		let personaID: Profile.Network.Persona.ID
		let dappMetadata: DappMetadata
		var personas: IdentifiedArrayOf<Profile.Network.Persona> = []
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
		case appeared
		case continueButtonTapped
	}

	enum InternalAction: Sendable, Equatable {
		case personasLoaded(IdentifiedArrayOf<Profile.Network.Persona>)
	}

	enum ChildAction: Sendable, Equatable {
		case persona(id: PersonaDataPermissionBox.State.ID, action: PersonaDataPermissionBox.Action)
		case destination(PresentationAction<Destinations.Action>)
	}

	enum DelegateAction: Sendable, Equatable {
		case continueButtonTapped
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
		case .continueButtonTapped:
			return .send(.delegate(.continueButtonTapped))
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .personasLoaded(personas):
			state.personas = personas
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .persona(id, action: .delegate(.edit)):
			if let persona = state.personas[id: id] {
//				state.destination = .editPersona(.init(
//					mode: .dapp(requiredFieldIDs: state.requiredFieldIDs),
//					avatarURL: URL(string: "something")!,
//					personaLabel: <#T##NonEmptyString#>,
//					existingFields: <#T##IdentifiedArrayOf<Profile.Network.Persona.Field>#>
//				))
			}
			return .none

		default:
			return .none
		}
	}
}
