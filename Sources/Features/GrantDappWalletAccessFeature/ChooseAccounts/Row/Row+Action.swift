import Foundation

// MARK: - ChooseAccounts.Row.Action
public extension ChooseAccounts.Row {
	enum Action: Sendable, Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - ChooseAccounts.Row.Action.ViewAction
public extension ChooseAccounts.Row.Action {
	enum ViewAction: Sendable, Equatable {
		case didSelect
	}
}

// MARK: - ChooseAccounts.Row.Action.InternalAction
public extension ChooseAccounts.Row.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - ChooseAccounts.Row.Action.InternalAction.SystemAction
public extension ChooseAccounts.Row.Action.InternalAction {
	enum SystemAction: Sendable, Equatable {}
}

// MARK: - ChooseAccounts.Row.Action.DelegateAction
public extension ChooseAccounts.Row.Action {
	enum DelegateAction: Sendable, Equatable {}
}
