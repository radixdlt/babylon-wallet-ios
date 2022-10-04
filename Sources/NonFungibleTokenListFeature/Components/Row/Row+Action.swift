import Foundation

// MARK: - NonFungibleTokenList.Row.Action
public extension NonFungibleTokenList.Row {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
	}
}

// MARK: - NonFungibleTokenList.Row.Action.InternalAction
public extension NonFungibleTokenList.Row.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

// MARK: - NonFungibleTokenList.Row.Action.InternalAction.UserAction
public extension NonFungibleTokenList.Row.Action.InternalAction {
	enum UserAction: Equatable {
		case toggleIsExpanded
	}
}

// MARK: - NonFungibleTokenList.Row.Action.InternalAction.SystemAction
public extension NonFungibleTokenList.Row.Action.InternalAction {
	enum SystemAction: Equatable {}
}

// MARK: - NonFungibleTokenList.Row.Action.CoordinatingAction
public extension NonFungibleTokenList.Row.Action {
	enum CoordinatingAction: Equatable {}
}
