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
		case nameNewEntity(NameNewEntity.Action)
		case selectGenesisFactorSource(SelectGenesisFactorSource.Action)
		case creationOfEntity(CreationOfEntity<CreateEntityCoordinator.Entity>.Action)
		case completion(CompletionAction)
	}
}

// MARK: - CreateEntityCoordinator.Action.DelegateAction
public extension CreateEntityCoordinator.Action {
	enum DelegateAction: Sendable, Equatable {
		case dismissed
		case completed
	}
}
