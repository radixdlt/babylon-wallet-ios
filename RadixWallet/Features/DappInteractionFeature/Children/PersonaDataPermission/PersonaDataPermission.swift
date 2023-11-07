import ComposableArchitecture
import SwiftUI

// MARK: - PersonaDataPermission
struct PersonaDataPermission: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let dappMetadata: DappMetadata
		let personaID: Profile.Network.Persona.ID
		var persona: PersonaDataPermissionBox.State?
		let requested: P2P.Dapp.Request.PersonaDataRequestItem

		@PresentationState
		var destination: Destination.State?

		init(
			dappMetadata: DappMetadata,
			personaID: Profile.Network.Persona.ID,
			requested: P2P.Dapp.Request.PersonaDataRequestItem
		) {
			self.dappMetadata = dappMetadata
			self.personaID = personaID
			self.requested = requested
		}
	}

	enum ViewAction: Sendable, Equatable {
		case task
		case continueButtonTapped(P2P.Dapp.Request.Response)
	}

	enum InternalAction: Sendable, Equatable {
		case personasLoaded(IdentifiedArrayOf<Profile.Network.Persona>)
	}

	enum ChildAction: Sendable, Equatable {
		case persona(PersonaDataPermissionBox.Action)
		case destination(PresentationAction<Destination.Action>)
	}

	enum DelegateAction: Sendable, Equatable {
		case personaUpdated(Profile.Network.Persona)
		case continueButtonTapped(P2P.Dapp.Request.Response)
	}

	struct Destination: Sendable, Reducer {
		enum State: Sendable, Hashable {
			case editPersona(EditPersona.State)
		}

		enum Action: Sendable, Equatable {
			case editPersona(EditPersona.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: /State.editPersona, action: /Action.editPersona) {
				EditPersona()
			}
		}
	}

	@Dependency(\.personasClient) var personasClient
	@Dependency(\.errorQueue) var errorQueue

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.persona, action: /Action.child .. ChildAction.persona) {
				PersonaDataPermissionBox()
			}
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destination()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			.run { send in
				for try await personas in await personasClient.personas() {
					guard !Task.isCancelled else {
						return
					}
					await send(.internal(.personasLoaded(personas)))
				}
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case let .continueButtonTapped(response):
			.send(.delegate(.continueButtonTapped(response)))
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .personasLoaded(personas):
			if let persona = personas[id: state.personaID] {
				state.persona = .init(persona: persona, requested: state.requested)
			}
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .persona(.delegate(.edit)):
			if let persona = state.persona {
				state.destination = .editPersona(.init(
					mode: .dapp(requiredEntries: Set(state.requested.kindRequests.keys)),
					persona: persona.persona
				))
			}
			return .none

		case let .destination(.presented(.editPersona(.delegate(.personaSaved(persona))))):
			return .send(.delegate(.personaUpdated(persona)))

		default:
			return .none
		}
	}
}
