import Asset

// MARK: - FungibleTokenList.Action
public extension FungibleTokenList {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
		case section(id: FungibleTokenCategory.CategoryType, action: FungibleTokenList.Section.Action)
	}
}

// MARK: - FungibleTokenList.Action.InternalAction
public extension FungibleTokenList.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

// MARK: - FungibleTokenList.Action.InternalAction.UserAction
public extension FungibleTokenList.Action.InternalAction {
	enum UserAction: Equatable {}
}

// MARK: - FungibleTokenList.Action.InternalAction.SystemAction
public extension FungibleTokenList.Action.InternalAction {
	enum SystemAction: Equatable {}
}

// MARK: - FungibleTokenList.Action.CoordinatingAction
public extension FungibleTokenList.Action {
	enum CoordinatingAction: Equatable {}
}
