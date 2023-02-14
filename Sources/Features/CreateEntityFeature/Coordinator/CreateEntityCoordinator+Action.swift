import FeaturePrelude
import Profile

// MARK: - CreateEntityCoordinator.Action
extension CreateEntityCoordinator {
	public enum Action: Sendable, Equatable {
		case view(ViewAction)
		case child(ChildAction)
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - CreateEntityCoordinator.Action.ViewAction
extension CreateEntityCoordinator.Action {
	public enum ViewAction: Sendable, Equatable {
		case dismiss
	}
}

// MARK: - CreateEntityCoordinator.Action.InternalAction
extension CreateEntityCoordinator.Action {
	public enum InternalAction: Sendable, Equatable {
		case loadFactorSourcesResult(TaskResult<FactorSources>, beforeCreatingEntityWithName: NonEmpty<String>)
	}
}

// MARK: - CreateEntityCoordinator.Action.ChildAction
extension CreateEntityCoordinator.Action {
	public enum ChildAction: Sendable, Equatable {
		public typealias Entity = CreateEntityCoordinator.Entity
		case step0_nameNewEntity(NameNewEntity<Entity>.Action)
		case step1_selectGenesisFactorSource(SelectGenesisFactorSource.Action)
		case step2_creationOfEntity(CreationOfEntity<Entity>.Action)
		case step3_completion(NewEntityCompletion<Entity>.Action)
	}
}

// MARK: - CreateEntityCoordinator.Action.DelegateAction
extension CreateEntityCoordinator.Action {
	public enum DelegateAction: Sendable, Equatable {
		case dismissed
		case completed
	}
}
