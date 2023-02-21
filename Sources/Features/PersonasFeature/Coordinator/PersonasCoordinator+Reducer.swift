import CreateEntityFeature
import FeaturePrelude

// MARK: - PersonasCoordinator
public struct PersonasCoordinator: Sendable, FeatureReducer {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.profileClient) var profileClient
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
		case .personaList(.delegate(.dismiss)):
			return .run { send in
				await send(.delegate(.dismiss))
			}

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

		case .createPersonaCoordinator(.delegate(.dismissed)):
			state.createPersonaCoordinator = nil
			return .none

		default:
			return .none
		}
	}
}

extension PersonasCoordinator {
	func loadPersonas() -> EffectTask<Action> {
		.run { send in
			await send(.internal(.loadPersonasResult(
				TaskResult {
					try await profileClient.getPersonas()
				}
			)))
		}
	}
}
