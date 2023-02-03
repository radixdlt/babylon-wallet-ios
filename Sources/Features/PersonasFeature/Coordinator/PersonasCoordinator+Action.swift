import CreateEntityFeature
import FeaturePrelude

// MARK: - PersonasCoordinator.Action
public extension PersonasCoordinator {
	enum ViewAction: Sendable, Equatable {
		case appeared
	}

	enum InternalAction: Sendable & Equatable {
		case loadPersonasResult(TaskResult<IdentifiedArrayOf<OnNetwork.Persona>>)
	}

	enum ChildAction: Sendable, Equatable {
		case personaList(PersonaList.Action)
		case createPersonaCoordinator(CreatePersonaCoordinator.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case dismiss
	}
}
