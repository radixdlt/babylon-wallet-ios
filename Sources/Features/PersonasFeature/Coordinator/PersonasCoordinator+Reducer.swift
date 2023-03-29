import CreateEntityFeature
import FeaturePrelude
import PersonasClient

// MARK: - PersonasCoordinator
public struct PersonasCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var personaList: PersonaList.State

		@PresentationState
		public var createPersonaCoordinator: CreatePersonaCoordinator.State?

		public var hasAnyPersonaOnAnyNetwork: Bool? = nil

		public init(
			personaList: PersonaList.State = .init(),
			createPersonaCoordinator: CreatePersonaCoordinator.State? = nil,
			hasAnyPersonaOnAnyNetwork: Bool? = nil
		) {
			self.personaList = personaList
			self.createPersonaCoordinator = createPersonaCoordinator
			self.hasAnyPersonaOnAnyNetwork = hasAnyPersonaOnAnyNetwork
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum InternalAction: Sendable & Equatable {
		case loadPersonasResult(TaskResult<IdentifiedArrayOf<Profile.Network.Persona>>)
		case hasAnyPersonaOnAnyNetwork(Bool)
	}

	public enum ChildAction: Sendable, Equatable {
		case personaList(PersonaList.Action)

		case createPersonaCoordinator(PresentationAction<CreatePersonaCoordinator.Action>)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.personasClient) var personasClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.personaList, action: /Action.child .. ChildAction.personaList) {
			PersonaList()
		}
		.ifLet(\.$createPersonaCoordinator, action: /Action.child .. ChildAction.createPersonaCoordinator) {
			CreatePersonaCoordinator()
		}

		Reduce(self.core)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return loadPersonas().concatenate(with: checkIfFirstPersonaByUserEver())
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadPersonasResult(.success(personas)):
			state.personaList.personas = .init(uniqueElements: personas.map(Persona.State.init))
			return .none
		case let .hasAnyPersonaOnAnyNetwork(hasAnyPersonaOnAnyNetwork):
			state.hasAnyPersonaOnAnyNetwork = hasAnyPersonaOnAnyNetwork
			return .none
		case let .loadPersonasResult(.failure(error)):
			errorQueue.schedule(error)
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .personaList(.delegate(.createNewPersona)):
			assert(state.hasAnyPersonaOnAnyNetwork != nil, "Should have checked 'hasAnyPersonaOnAnyNetwork' already")
			let isFirstOnThisNetwork = state.personaList.personas.count == 0
			let isFirstOnAnyNetwork = state.hasAnyPersonaOnAnyNetwork ?? true

			state.createPersonaCoordinator = .init(
				config: .init(
					purpose: .newPersonaFromSettings(isFirst: isFirstOnThisNetwork)
				),
				displayIntroduction: { _ in
					isFirstOnAnyNetwork
				}
			)
			return .none

		case .createPersonaCoordinator(.presented(.delegate(.completed))):
			return loadPersonas()

		default:
			return .none
		}
	}
}

extension PersonasCoordinator {
	func loadPersonas() -> EffectTask<Action> {
		.task {
			let result = await TaskResult {
				try await personasClient.getPersonas()
			}
			return .internal(.loadPersonasResult(result))
		}
	}

	func checkIfFirstPersonaByUserEver() -> EffectTask<Action> {
		.task {
			let hasAnyPersonaOnAnyNetwork = await personasClient.hasAnyPersonaOnAnyNetworks()
			return .internal(.hasAnyPersonaOnAnyNetwork(hasAnyPersonaOnAnyNetwork))
		}
	}
}
