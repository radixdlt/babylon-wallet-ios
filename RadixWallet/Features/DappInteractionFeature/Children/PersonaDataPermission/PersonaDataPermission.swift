import ComposableArchitecture
import SwiftUI

// MARK: - PersonaDataPermission
struct PersonaDataPermission: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let dappMetadata: DappMetadata
		let personaID: Persona.ID
		var persona: PersonaDataPermissionBox.State?
		let requested: DappToWalletInteractionPersonaDataRequestItem

		@PresentationState
		var destination: Destination.State?

		init(
			dappMetadata: DappMetadata,
			personaID: Persona.ID,
			requested: DappToWalletInteractionPersonaDataRequestItem
		) {
			self.dappMetadata = dappMetadata
			self.personaID = personaID
			self.requested = requested
		}
	}

	enum ViewAction: Sendable, Equatable {
		case task
		case continueButtonTapped(WalletToDappInteractionPersonaDataRequestResponseItem)
	}

	enum InternalAction: Sendable, Equatable {
		case personasLoaded(Personas)
	}

	enum ChildAction: Sendable, Equatable {
		case persona(PersonaDataPermissionBox.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case personaUpdated(Persona)
		case continueButtonTapped(WalletToDappInteractionPersonaDataRequestResponseItem)
	}

	struct Destination: DestinationReducer {
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
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

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
					mode: .dapp(
						persona: persona.persona,
						requiredEntries: Set(state.requested.kindRequests.keys)
					)
				))
			}
			return .none

		default:
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .editPersona(.delegate(.personaSaved(persona))):
			.send(.delegate(.personaUpdated(persona)))

		default:
			.none
		}
	}
}
