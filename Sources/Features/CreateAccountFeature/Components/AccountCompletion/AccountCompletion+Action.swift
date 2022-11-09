import Foundation

// MARK: - AccountCompletion.Action
public extension AccountCompletion {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - AccountCompletion.Action.ViewAction
public extension AccountCompletion.Action {
	enum ViewAction: Equatable {}
}

// MARK: - AccountCompletion.Action.InternalAction
public extension AccountCompletion.Action {
	enum InternalAction: Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - AccountCompletion.Action.InternalAction.SystemAction
public extension AccountCompletion.Action.InternalAction {
	enum SystemAction: Equatable {}
}

// MARK: - AccountCompletion.Action.DelegateAction
public extension AccountCompletion.Action {
	enum DelegateAction: Equatable {}
}
