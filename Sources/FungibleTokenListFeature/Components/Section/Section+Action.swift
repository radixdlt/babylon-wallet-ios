import Asset
import Foundation

// MARK: - FungibleTokenList.Section.Action
public extension FungibleTokenList.Section {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
		case asset(id: FungibleTokenContainer.ID, action: FungibleTokenList.Row.Action)
	}
}

// MARK: - FungibleTokenList.Section.Action.InternalAction
public extension FungibleTokenList.Section.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

// MARK: - FungibleTokenList.Section.Action.InternalAction.UserAction
public extension FungibleTokenList.Section.Action.InternalAction {
	enum UserAction: Equatable {}
}

// MARK: - FungibleTokenList.Section.Action.InternalAction.SystemAction
public extension FungibleTokenList.Section.Action.InternalAction {
	enum SystemAction: Equatable {}
}

// MARK: - FungibleTokenList.Section.Action.CoordinatingAction
public extension FungibleTokenList.Section.Action {
	enum CoordinatingAction: Equatable {}
}
