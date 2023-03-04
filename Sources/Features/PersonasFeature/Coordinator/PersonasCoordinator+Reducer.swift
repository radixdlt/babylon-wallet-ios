import CreateEntityFeature
import FeaturePrelude
import PersonasClient

// MARK: - PersonasCoordinator
public struct PersonasCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var personaList: PersonaList.State

		public var createPersonaCoordinator: CreatePersonaCoordinator.State?

		public init(
			personaList: PersonaList.State = .init(),
			createPersonaCoordinator: CreatePersonaCoordinator.State? = nil
		) {
			self.personaList = personaList
			self.createPersonaCoordinator = createPersonaCoordinator
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum InternalAction: Sendable & Equatable {
		case loadPersonasResult(TaskResult<IdentifiedArrayOf<OnNetwork.Persona>>)
	}

	public enum ChildAction: Sendable, Equatable {
		case personaList(PersonaList.Action)
		case createPersonaCoordinator(CreatePersonaCoordinator.Action)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.personasClient) var personasClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.personaList, action: /Action.child .. ChildAction.personaList) {
			PersonaList()
		}
		.ifLet(\.createPersonaCoordinator, action: /Action.child .. ChildAction.createPersonaCoordinator) {
			CreatePersonaCoordinator()
		}

		Reduce(self.core)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return loadPersonas()
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadPersonasResult(.success(personas)):
			state.personaList.personas = .init(uniqueElements: personas.map(Persona.State.init))
			return .none
		case let .loadPersonasResult(.failure(error)):
			errorQueue.schedule(error)
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .personaList(.delegate(.createNewPersona)):
			let isFirst = state.personaList.personas.count == 0
			state.createPersonaCoordinator = .init(config: .init(
				isFirstEntity: isFirst,
				canBeDismissed: true,
				navigationButtonCTA: .goBackToPersonaList
			))
			return .none

		case .createPersonaCoordinator(.delegate(.completed)):
			state.createPersonaCoordinator = nil
			return loadPersonas()

		case .createPersonaCoordinator(.delegate(.dismiss)):
			state.createPersonaCoordinator = nil
			return .none

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
}
