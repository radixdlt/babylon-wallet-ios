import ComposableArchitecture
import SwiftUI

// MARK: - AccountPermission
struct OneTimePersonaData: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let dappMetadata: DappMetadata
		var personas: IdentifiedArrayOf<PersonaDataPermissionBox.State> = []
		var selectedPersona: PersonaDataPermissionBox.State?
		let requested: DappToWalletInteractionPersonaDataRequestItem

		var personaPrimacy: PersonaPrimacy? = nil

		@PresentationState
		var destination: Destination.State?

		init(
			dappMetadata: DappMetadata,
			requested: DappToWalletInteractionPersonaDataRequestItem,
			personaPrimacy: PersonaPrimacy? = nil
		) {
			self.dappMetadata = dappMetadata
			self.requested = requested
			self.personaPrimacy = personaPrimacy
		}
	}

	enum ViewAction: Sendable, Equatable {
		case task
		case appeared
		case selectedPersonaChanged(PersonaDataPermissionBox.State?)
		case createNewPersonaButtonTapped
		case continueButtonTapped(WalletToDappInteractionPersonaDataRequestResponseItem)
	}

	enum InternalAction: Sendable, Equatable {
		case personasLoaded(Personas)
		case personaPrimacyDetermined(PersonaPrimacy)
	}

	enum ChildAction: Sendable, Equatable {
		case persona(id: PersonaDataPermissionBox.State.ID, action: PersonaDataPermissionBox.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case personaUpdated(Persona)
		case continueButtonTapped(WalletToDappInteractionPersonaDataRequestResponseItem)
	}

	public struct Destination: DestinationReducer {
		enum State: Sendable, Hashable {
			case editPersona(EditPersona.State)
			case createPersona(CreatePersonaCoordinator.State)
		}

		enum Action: Sendable, Equatable {
			case editPersona(EditPersona.Action)
			case createPersona(CreatePersonaCoordinator.Action)
		}

		var body: some ReducerOf<Self> {
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

	var body: some ReducerOf<Self> {
		Reduce(core)
			.forEach(\.personas, action: /Action.child .. ChildAction.persona) {
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
			return .run { send in
				for try await personas in await personasClient.personas() {
					guard !Task.isCancelled else {
						return
					}
					await send(.internal(.personasLoaded(personas)))
				}
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case .appeared:
			return .run { send in
				await send(.internal(.personaPrimacyDetermined(
					personasClient.determinePersonaPrimacy()
				)))
			}

		case let .selectedPersonaChanged(persona):
			state.selectedPersona = persona
			return .none

		case .createNewPersonaButtonTapped:
			assert(state.personaPrimacy != nil, "Should have checked 'personaPrimacy' already")
			let personaPrimacy = state.personaPrimacy ?? .firstOnAnyNetwork

			state.destination = .createPersona(.init(
				config: .init(
					personaPrimacy: personaPrimacy,
					navigationButtonCTA: .goBackToChoosePersonas
				))
			)
			return .none

		case let .continueButtonTapped(request):
			return .send(.delegate(.continueButtonTapped(request)))
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .personaPrimacyDetermined(personaPrimacy):
			state.personaPrimacy = personaPrimacy
			return .none

		case let .personasLoaded(personas):
			state.personas = IdentifiedArrayOf(
				uncheckedUniqueElements: personas.map {
					.init(persona: $0, requested: state.requested)
				}
			)
			if let selectedPersona = (state.selectedPersona?.id).flatMap({ personas[id: $0] }) {
				state.selectedPersona = .init(persona: selectedPersona, requested: state.requested)
			}

			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .persona(id, .delegate(.edit)):
			if let persona = state.personas[id: id] {
				state.destination = .editPersona(.init(
					mode: .dapp(requiredEntries: Set(state.requested.kindRequests.keys)),
					persona: persona.persona
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
			return .send(.delegate(.personaUpdated(persona)))

		case .createPersona(.delegate(.completed)):
			state.personaPrimacy = .notFirstOnCurrentNetwork
			return .none

		default:
			return .none
		}
	}
}
