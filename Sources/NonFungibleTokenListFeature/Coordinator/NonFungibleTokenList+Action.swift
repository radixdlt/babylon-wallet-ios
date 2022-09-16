import Asset
import Foundation

// MARK: - NonFungibleTokenList.Action
public extension NonFungibleTokenList {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
		case asset(id: NonFungibleTokenContainer.ID, action: NonFungibleTokenList.Row.Action)
	}
}

// MARK: - NonFungibleTokenList.Action.InternalAction
public extension NonFungibleTokenList.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

// MARK: - NonFungibleTokenList.Action.InternalAction.UserAction
public extension NonFungibleTokenList.Action.InternalAction {
	enum UserAction: Equatable {}
}

// MARK: - NonFungibleTokenList.Action.InternalAction.SystemAction
public extension NonFungibleTokenList.Action.InternalAction {
	enum SystemAction: Equatable {}
}

// MARK: - NonFungibleTokenList.Action.CoordinatingAction
public extension NonFungibleTokenList.Action {
	enum CoordinatingAction: Equatable {}
}
