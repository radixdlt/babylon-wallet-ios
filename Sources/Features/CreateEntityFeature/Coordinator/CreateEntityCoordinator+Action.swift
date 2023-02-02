import FeaturePrelude
import Profile

// MARK: - CreateEntityCoordinator.Action
public extension CreateEntityCoordinator {
	enum Action: Sendable, Equatable {
		case view(ViewAction)
		case child(ChildAction)
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - CreateEntityCoordinator.Action.ViewAction
public extension CreateEntityCoordinator.Action {
	enum ViewAction: Sendable, Equatable {
		case dismiss
	}
}

// MARK: - CreateEntityCoordinator.Action.InternalAction
public extension CreateEntityCoordinator.Action {
	enum InternalAction: Sendable, Equatable {
		// FIXME: handle this better, perhaphs in fact we SHOULD allow accounts to be empty, to have an empty profile here
		case generateProfile(TaskResult<OnNetwork.Account>)
		case loadFactorSourcesResult(TaskResult<FactorSources>, beforeCreatingEntityWithName: String)
	}
}

// MARK: - CreateEntityCoordinator.Action.ChildAction
public extension CreateEntityCoordinator.Action {
	enum ChildAction: Sendable, Equatable {
		public typealias Entity = CreateEntityCoordinator.Entity
		case step0_nameNewEntity(NameNewEntity<Entity>.Action)
		case step1_selectGenesisFactorSource(SelectGenesisFactorSource.Action)
		case step2_creationOfEntity(CreationOfEntity<Entity>.Action)
		case step3_completion(NewEntityCompletion<Entity>.Action)
	}
}

// MARK: - CreateEntityCoordinator.Action.DelegateAction
public extension CreateEntityCoordinator.Action {
	enum DelegateAction: Sendable, Equatable {
		case dismissed
		case completed
	}
}
