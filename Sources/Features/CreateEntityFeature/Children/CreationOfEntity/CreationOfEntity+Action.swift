import FeaturePrelude

// MARK: - CreationOfEntity.Action
extension CreationOfEntity {
	public enum Action: Sendable, Equatable {
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

extension CreationOfEntity.Action {
	public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
}

// MARK: - CreationOfEntity.Action.ViewAction
extension CreationOfEntity.Action {
	public enum ViewAction: Sendable, Equatable {
		case appeared
	}
}

// MARK: - CreationOfEntity.Action.InternalAction
extension CreationOfEntity.Action {
	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - CreationOfEntity.Action.SystemAction
extension CreationOfEntity.Action {
	public enum SystemAction: Sendable, Equatable {
		case createEntityResult(TaskResult<Entity>)
	}
}

// MARK: - CreationOfEntity.Action.DelegateAction
extension CreationOfEntity.Action {
	public enum DelegateAction: Sendable, Equatable {
		case createdEntity(Entity)
		case createEntityFailed
	}
}
