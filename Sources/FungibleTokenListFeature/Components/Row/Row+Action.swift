import Foundation

// MARK: - FungibleTokenList.Row.Action
public extension FungibleTokenList.Row {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
	}
}

// MARK: - FungibleTokenList.Row.Action.InternalAction
public extension FungibleTokenList.Row.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

// MARK: - FungibleTokenList.Row.Action.InternalAction.UserAction
public extension FungibleTokenList.Row.Action.InternalAction {
	enum UserAction: Equatable {}
}

// MARK: - FungibleTokenList.Row.Action.InternalAction.SystemAction
public extension FungibleTokenList.Row.Action.InternalAction {
	enum SystemAction: Equatable {}
}

// MARK: - FungibleTokenList.Row.Action.CoordinatingAction
public extension FungibleTokenList.Row.Action {
	enum CoordinatingAction: Equatable {}
}
