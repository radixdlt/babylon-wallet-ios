import ComposableArchitecture
import SwiftUI

// MARK: - PersonasCoordinator
public struct PersonasCoordinator: Sendable, FeatureReducer {
	// MARK: - State

	public struct State: Sendable, Hashable {
		public var personaList: PersonaList.State

		@PresentationState
		public var destination: Destination.State? = nil

		/// Determines if the persona is first ever created across networks.
		public var personaPrimacy: PersonaPrimacy? = nil

		public init(
			personaList: PersonaList.State = .init(),
			destination: Destination.State? = nil,
			personaPrimacy: PersonaPrimacy? = nil
		) {
			self.personaList = personaList
			self.destination = destination
			self.personaPrimacy = personaPrimacy
		}
	}

	// MARK: - Action

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum InternalAction: Sendable & Equatable {
		case personaPrimacyDetermined(PersonaPrimacy)
		case loadedPersonaDetails(PersonaDetails.State)
		case finishedWritingDownMnemonicForPersonas(ids: Set<Profile.Network.Persona.ID>)
	}

	public enum ChildAction: Sendable, Equatable {
		case personaList(PersonaList.Action)
		case destination(PresentationAction<Destination.Action>)
	}

	// MARK: - Destination

	public struct Destination: Reducer {
		public enum State: Equatable, Hashable {
			case createPersonaCoordinator(CreatePersonaCoordinator.State)
			case personaDetails(PersonaDetails.State)
			case exportMnemonic(ExportMnemonic.State)
		}

		public enum Action: Equatable {
			case createPersonaCoordinator(CreatePersonaCoordinator.Action)
			case personaDetails(PersonaDetails.Action)
			case exportMnemonic(ExportMnemonic.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.createPersonaCoordinator, action: /Action.createPersonaCoordinator) {
				CreatePersonaCoordinator()
			}
			Scope(state: /State.personaDetails, action: /Action.personaDetails) {
				PersonaDetails()
			}
			Scope(state: /State.exportMnemonic, action: /Action.exportMnemonic) {
				ExportMnemonic()
			}
		}
	}

	// MARK: - Reducer

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.personasClient) var personasClient
	@Dependency(\.authorizedDappsClient) var authorizedDappsClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.personaList, action: /Action.child .. ChildAction.personaList) {
			PersonaList()
		}
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destination()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			.run { send in
				await send(.internal(.personaPrimacyDetermined(
					personasClient.determinePersonaPrimacy()
				)))
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .personaPrimacyDetermined(personaPrimacy):
			state.personaPrimacy = personaPrimacy
			return .none

		case let .loadedPersonaDetails(personaDetails):
			state.destination = .personaDetails(personaDetails)
			return .none

		case let .finishedWritingDownMnemonicForPersonas(ids):
			state.personaList.personas.mutateAll { persona in
				if ids.contains(persona.id) {
					persona.shouldWriteDownMnemonic = false
				}
			}
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .personaList(.delegate(.createNewPersona)):
			assert(state.personaPrimacy != nil, "Should have checked 'personaPrimacy' already")
			let personaPrimacy = state.personaPrimacy ?? .firstOnAnyNetwork

			let coordinatorState = CreatePersonaCoordinator.State(
				config: .init(
					personaPrimacy: personaPrimacy,
					navigationButtonCTA: .goBackToPersonaListInSettings
				)
			)

			state.destination = .createPersonaCoordinator(coordinatorState)

			return .none

		case let .personaList(.delegate(.openDetails(persona))):
			return .run { send in
				let dApps = try await authorizedDappsClient.getDappsAuthorizedByPersona(persona.id)
					.map(PersonaDetails.State.DappInfo.init)
				let personaDetailsState = PersonaDetails.State(.general(persona, dApps: .init(uniqueElements: dApps)))
				await send(.internal(.loadedPersonaDetails(personaDetailsState)))
			}

		case let .personaList(.delegate(.exportMnemonic(persona))):
			return exportMnemonic(controlling: persona, state: &state)

		case .personaList:
			return .none

		case let .destination(.presented(.createPersonaCoordinator(.delegate(delegateAction)))):
			switch delegateAction {
			case .dismissed:
				state.destination = nil
				return .none

			case .completed:
				state.destination = nil
				state.personaPrimacy = .notFirstOnCurrentNetwork
				return .none
			}

		case .destination(.presented(.personaDetails(.delegate(.personaHidden)))):
			state.destination = nil
			return .none

		case let .destination(.presented(.exportMnemonic(.delegate(.doneViewing(idOfBackedUpFactorSource))))):
			state.destination = nil
			guard let idOfBackedUpFactorSource else {
				return .none
			}

			return .run { send in
				let personas = try await personasClient.getPersonas()
				let personasToRefresh = personas.filter {
					$0.deviceFactorSourceID == idOfBackedUpFactorSource
				}.map(\.id)

				await send(.internal(.finishedWritingDownMnemonicForPersonas(ids: Set(personasToRefresh))))
			}

		case .destination:
			return .none
		}
	}

	private func exportMnemonic(
		controlling persona: Profile.Network.Persona,
		state: inout State
	) -> Effect<Action> {
		exportMnemonic(
			controlling: persona,
			onSuccess: {
				state.destination = .exportMnemonic(.export(
					$0,
					title: L10n.RevealSeedPhrase.title,
					context: .fromBackupPrompt
				))
			}
		)
	}
}
