import CreatePersonaFeature
import FeaturePrelude
import PersonaDetailsFeature
import PersonasClient

// MARK: - PersonasCoordinator
public struct PersonasCoordinator: Sendable, FeatureReducer {
	// MARK: - State

	public struct State: Sendable, Hashable {
		public var personaList: PersonaList.State

		@PresentationState
		public var destination: Destination.State? = nil

		public var isFirstPersonaOnAnyNetwork: Bool? = nil

		public init(
			personaList: PersonaList.State = .init(),
			destination: Destination.State? = nil,
			isFirstPersonaOnAnyNetwork: Bool? = nil
		) {
			self.personaList = personaList
			self.destination = destination
			self.isFirstPersonaOnAnyNetwork = isFirstPersonaOnAnyNetwork
		}
	}

	// MARK: - Action

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum InternalAction: Sendable & Equatable {
		case isFirstPersonaOnAnyNetwork(Bool)
		case loadedPersonaDetails(PersonaDetails.State)
	}

	public enum ChildAction: Sendable, Equatable {
		case personaList(PersonaList.Action)
		case destination(PresentationAction<Destination.Action>)
	}

	// MARK: - Destination

	public struct Destination: ReducerProtocol {
		public enum State: Equatable, Hashable {
			case createPersonaCoordinator(CreatePersonaCoordinator.State)
			case personaDetails(PersonaDetails.State)
		}

		public enum Action: Equatable {
			case createPersonaCoordinator(CreatePersonaCoordinator.Action)
			case personaDetails(PersonaDetails.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.createPersonaCoordinator, action: /Action.createPersonaCoordinator) {
				CreatePersonaCoordinator()
			}
			Scope(state: /State.personaDetails, action: /Action.personaDetails) {
				PersonaDetails()
			}
		}
	}

	// MARK: - Reducer

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.personasClient) var personasClient
	@Dependency(\.authorizedDappsClient) var authorizedDappsClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.personaList, action: /Action.child .. ChildAction.personaList) {
			PersonaList()
		}
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destination()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return checkIfFirstPersonaByUserEver()
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .isFirstPersonaOnAnyNetwork(isFirstPersonaOnAnyNetwork):
			state.isFirstPersonaOnAnyNetwork = isFirstPersonaOnAnyNetwork
			return .none

		case let .loadedPersonaDetails(personaDetails):
			state.destination = .personaDetails(personaDetails)
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .personaList(.delegate(.createNewPersona)):
			assert(state.isFirstPersonaOnAnyNetwork != nil, "Should have checked 'isFirstPersonaOnAnyNetwork' already")
			let isFirstOnThisNetwork = state.personaList.personas.isEmpty
			let isFirstOnAnyNetwork = state.isFirstPersonaOnAnyNetwork ?? true

			let coordinatorState = CreatePersonaCoordinator.State(
				config: .init(
					personaPrimacy: .init(
						firstOnAnyNetwork: isFirstOnAnyNetwork,
						firstOnCurrent: isFirstOnThisNetwork
					),
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

		case .personaList:
			return .none

		case let .destination(.presented(.createPersonaCoordinator(.delegate(delegateAction)))):
			switch delegateAction {
			case .dismissed:
				state.destination = nil
				return .none

			case .completed:
				state.destination = nil
				state.isFirstPersonaOnAnyNetwork = false
				return .none
			}

		case .destination:
			return .none
		}
	}
}

extension PersonasCoordinator {
	func checkIfFirstPersonaByUserEver() -> EffectTask<Action> {
		.run { send in
			let hasAnyPersonaOnAnyNetwork = await personasClient.hasAnyPersonaOnAnyNetwork()
			let isFirstPersonaOnAnyNetwork = !hasAnyPersonaOnAnyNetwork
			await send(.internal(.isFirstPersonaOnAnyNetwork(isFirstPersonaOnAnyNetwork)))
		}
	}
}
