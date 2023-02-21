import FeaturePrelude

// MARK: - NewEntityCompletion.Action
extension NewEntityCompletion {
	// MARK: Action
	public enum Action: Sendable, Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - NewEntityCompletion.Action.ViewAction
extension NewEntityCompletion.Action {
	public enum ViewAction: Sendable, Equatable {
		case goToDestination
	}
}

// MARK: - NewEntityCompletion.Action.InternalAction
extension NewEntityCompletion.Action {
	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - NewEntityCompletion.Action.InternalAction.SystemAction
extension NewEntityCompletion.Action.InternalAction {
	public enum SystemAction: Sendable, Equatable {}
}

// MARK: - NewEntityCompletion.Action.DelegateAction
extension NewEntityCompletion.Action {
	public enum DelegateAction: Sendable, Equatable {
		case completed
	}
}
