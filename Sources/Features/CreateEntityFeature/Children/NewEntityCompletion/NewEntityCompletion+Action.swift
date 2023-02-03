import FeaturePrelude

// MARK: - NewEntityCompletion.Action
public extension NewEntityCompletion {
	// MARK: Action
	enum Action: Sendable, Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - NewEntityCompletion.Action.ViewAction
public extension NewEntityCompletion.Action {
	enum ViewAction: Sendable, Equatable {
		case goToDestination
	}
}

// MARK: - NewEntityCompletion.Action.InternalAction
public extension NewEntityCompletion.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - NewEntityCompletion.Action.InternalAction.SystemAction
public extension NewEntityCompletion.Action.InternalAction {
	enum SystemAction: Sendable, Equatable {}
}

// MARK: - NewEntityCompletion.Action.DelegateAction
public extension NewEntityCompletion.Action {
	enum DelegateAction: Sendable, Equatable {
		case completed
	}
}
