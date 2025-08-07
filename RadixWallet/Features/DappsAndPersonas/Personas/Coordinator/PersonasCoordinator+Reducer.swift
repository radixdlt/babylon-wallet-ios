import ComposableArchitecture
import SwiftUI

// MARK: - PersonasCoordinator
struct PersonasCoordinator: Sendable, FeatureReducer {
	// MARK: - State

	struct State: Sendable, Hashable {
		var personaList: PersonaList.State

		@PresentationState
		var destination: Destination.State? = nil

		/// Determines if the persona is first ever created across networks.
		var personaPrimacy: PersonaPrimacy? = nil

		init(
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

	enum ViewAction: Sendable, Equatable {
		case appeared
	}

	enum InternalAction: Sendable & Equatable {
		case personaPrimacyDetermined(PersonaPrimacy)
		case loadedPersonaDetails(PersonaDetails.State)
	}

	enum ChildAction: Sendable, Equatable {
		case personaList(PersonaList.Action)
	}

	// MARK: - Destination

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case createPersonaCoordinator(CreatePersonaCoordinator.State)
			case personaDetails(PersonaDetails.State)
			case securityCenter(SecurityCenter.State)
			case displayMnemonic(DisplayMnemonic.State)
			case enterMnemonic(ImportMnemonicForFactorSource.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case createPersonaCoordinator(CreatePersonaCoordinator.Action)
			case personaDetails(PersonaDetails.Action)
			case securityCenter(SecurityCenter.Action)
			case displayMnemonic(DisplayMnemonic.Action)
			case enterMnemonic(ImportMnemonicForFactorSource.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.createPersonaCoordinator, action: \.createPersonaCoordinator) {
				CreatePersonaCoordinator()
			}
			Scope(state: \.personaDetails, action: \.personaDetails) {
				PersonaDetails()
			}
			Scope(state: \.securityCenter, action: \.securityCenter) {
				SecurityCenter()
			}
			Scope(state: \.displayMnemonic, action: \.displayMnemonic) {
				DisplayMnemonic()
			}
			Scope(state: \.enterMnemonic, action: \.enterMnemonic) {
				ImportMnemonicForFactorSource()
			}
		}
	}

	// MARK: - Reducer

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.personasClient) var personasClient
	@Dependency(\.authorizedDappsClient) var authorizedDappsClient

	init() {}

	var body: some ReducerOf<Self> {
		Scope(state: \.personaList, action: /Action.child .. ChildAction.personaList) {
			PersonaList()
		}
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			.run { send in
				await send(.internal(.personaPrimacyDetermined(
					personasClient.determinePersonaPrimacy()
				)))
			}
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .personaPrimacyDetermined(personaPrimacy):
			state.personaPrimacy = personaPrimacy
			return .none

		case let .loadedPersonaDetails(personaDetails):
			state.destination = .personaDetails(personaDetails)
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
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
				let personaDetailsState = PersonaDetails.State(persona: persona, .general(dApps: dApps.asIdentified()))
				await send(.internal(.loadedPersonaDetails(personaDetailsState)))
			}

		case let .personaList(.delegate(.presentSecurityProblemHandler(.securityCenter(securityCenterState)))):
			state.destination = .securityCenter(securityCenterState)
			return .none

		case let .personaList(.delegate(.presentSecurityProblemHandler(.displayMnemonic(displayMnemonicState)))):
			state.destination = .displayMnemonic(displayMnemonicState)
			return .none

		case let .personaList(.delegate(.presentSecurityProblemHandler(.enterMnemonic(enterMnemonicState)))):
			state.destination = .enterMnemonic(enterMnemonicState)
			return .none

		default:
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .createPersonaCoordinator(.delegate(delegateAction)):
			switch delegateAction {
			case .dismissed:
				state.destination = nil
				return .none

			case .completed:
				state.destination = nil
				state.personaPrimacy = .notFirstOnCurrentNetwork
				return .none
			}

		case .personaDetails(.delegate(.personaHidden)):
			state.destination = nil
			return .none

		case .displayMnemonic(.delegate(.backedUp)):
			state.destination = nil
			return .none

		case .enterMnemonic(.delegate(.imported)):
			state.destination = nil
			return .none

		default:
			return .none
		}
	}
}
