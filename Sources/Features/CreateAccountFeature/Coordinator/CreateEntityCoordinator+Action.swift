import FeaturePrelude

// MARK: - CreateEntityCoordinator.Action
public extension CreateEntityCoordinator {
	enum Action: Sendable, Equatable {
		case child(ChildAction)
		case delegate(DelegateAction)
	}
}

// MARK: - CreateEntityCoordinator.Action.ChildAction
public extension CreateEntityCoordinator.Action {
	enum ChildAction: Sendable, Equatable {
		public typealias Entity = CreateEntityCoordinator.Entity
		case step0_nameNewEntity(NameNewEntity<Entity>.Action)
		case step1_selectGenesisFactorSource(SelectGenesisFactorSource.Action)
		case step2_creationOfEntity(CreationOfEntity<Entity>.Action)
		case step3_completion(CompletionAction)
	}
}

// MARK: - CreateEntityCoordinator.Action.DelegateAction
public extension CreateEntityCoordinator.Action {
	enum DelegateAction: Sendable, Equatable {
		case dismissed
		case completed
	}
}
