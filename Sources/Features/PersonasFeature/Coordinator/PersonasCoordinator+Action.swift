import CreateEntityFeature
import FeaturePrelude

// MARK: - PersonasCoordinator.Action
extension PersonasCoordinator {
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

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
	}
}
