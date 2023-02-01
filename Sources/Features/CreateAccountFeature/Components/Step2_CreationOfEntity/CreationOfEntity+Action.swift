import FeaturePrelude

// MARK: - CreationOfEntity.Action
public extension CreationOfEntity {
	enum Action: Sendable, Equatable {
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

public extension CreationOfEntity.Action {
	static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
}

// MARK: - CreationOfEntity.Action.ViewAction
public extension CreationOfEntity.Action {
	enum ViewAction: Sendable, Equatable {
		case appeared
	}
}

// MARK: - CreationOfEntity.Action.InternalAction
public extension CreationOfEntity.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - CreationOfEntity.Action.SystemAction
public extension CreationOfEntity.Action {
	enum SystemAction: Sendable, Equatable {}
}

// MARK: - CreationOfEntity.Action.DelegateAction
public extension CreationOfEntity.Action {
	enum DelegateAction: Sendable, Equatable {
		case createdEntity(Entity)
	}
}
