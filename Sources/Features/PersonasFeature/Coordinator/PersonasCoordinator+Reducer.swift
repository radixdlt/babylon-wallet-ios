import CreateEntityFeature
import FeaturePrelude
import PersonaDetailsFeature
import PersonasClient

// MARK: - PersonasCoordinator
public struct PersonasCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var personaList: PersonaList.State

		@PresentationState
		public var createPersonaCoordinator: CreatePersonaCoordinator.State? = nil

		@PresentationState
		public var personaDetails: PersonaDetails.State? = nil

		public var isFirstPersonaOnAnyNetwork: Bool? = nil

		public init(
			personaList: PersonaList.State = .init(),
			createPersonaCoordinator: CreatePersonaCoordinator.State? = nil,
			isFirstPersonaOnAnyNetwork: Bool? = nil
		) {
			self.personaList = personaList
			self.createPersonaCoordinator = createPersonaCoordinator
			self.isFirstPersonaOnAnyNetwork = isFirstPersonaOnAnyNetwork
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum InternalAction: Sendable & Equatable {
		case isFirstPersonaOnAnyNetwork(Bool)
		case loadedPersonaDetails(PersonaDetails.State)
	}

	public enum ChildAction: Sendable, Equatable {
		case personaList(PersonaList.Action)

		case createPersonaCoordinator(PresentationAction<CreatePersonaCoordinator.Action>)
		case personaDetails(PresentationAction<PersonaDetails.Action>)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.personasClient) var personasClient
	@Dependency(\.authorizedDappsClient) var authorizedDappsClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.personaList, action: /Action.child .. ChildAction.personaList) {
			PersonaList()
		}
		Reduce(core)
			.ifLet(\.$createPersonaCoordinator, action: /Action.child .. ChildAction.createPersonaCoordinator) {
				CreatePersonaCoordinator()
			}
			.ifLet(\.$personaDetails, action: /Action.child .. ChildAction.personaDetails) {
				PersonaDetails()
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
			state.personaDetails = personaDetails
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .personaDetails:
			return .none

		case .personaList(.delegate(.createNewPersona)):
			assert(state.isFirstPersonaOnAnyNetwork != nil, "Should have checked 'isFirstPersonaOnAnyNetwork' already")
			let isFirstOnThisNetwork = state.personaList.personas.count == 0
			let isFirstOnAnyNetwork = state.isFirstPersonaOnAnyNetwork ?? true

			state.createPersonaCoordinator = .init(
				config: .init(
					purpose: .newPersonaFromSettings(isFirst: isFirstOnThisNetwork)
				),
				displayIntroduction: { _ in
					isFirstOnAnyNetwork
				}
			)
			return .none

		case let .personaList(.delegate(.openDetails(persona))):
			return .task {
				let dApps = try await authorizedDappsClient.getDappsAuthorizedByPersona(persona.id)
					.map(PersonaDetails.State.DappInfo.init)
				let personaDetails = PersonaDetails.State(.general(persona, dApps: .init(uniqueElements: dApps)))
				return .internal(.loadedPersonaDetails(personaDetails))
			}

		case .personaList:
			return .none

		case .createPersonaCoordinator(.presented(.delegate(.dismissed))):
			state.createPersonaCoordinator = nil
			return .none

		case .createPersonaCoordinator(.presented(.delegate(.completed))):
			state.createPersonaCoordinator = nil
			state.isFirstPersonaOnAnyNetwork = false
			return .none

		case .createPersonaCoordinator:
			return .none
		}
	}
}

extension PersonasCoordinator {
	func checkIfFirstPersonaByUserEver() -> EffectTask<Action> {
		.task {
			let hasAnyPersonaOnAnyNetwork = await personasClient.hasAnyPersonaOnAnyNetwork()
			let isFirstPersonaOnAnyNetwork = !hasAnyPersonaOnAnyNetwork
			return .internal(.isFirstPersonaOnAnyNetwork(isFirstPersonaOnAnyNetwork))
		}
	}
}
