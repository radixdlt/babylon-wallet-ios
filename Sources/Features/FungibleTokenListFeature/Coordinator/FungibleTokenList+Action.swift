import Asset
import FungibleTokenDetailsFeature

// MARK: - FungibleTokenList.Action
public extension FungibleTokenList {
	// MARK: Action
	enum Action: Equatable {
		case child(ChildAction)
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - FungibleTokenList.Action.ChildAction
public extension FungibleTokenList.Action {
	enum ChildAction: Equatable {
		case section(id: FungibleTokenCategory.CategoryType, action: FungibleTokenList.Section.Action)
		case details(FungibleTokenDetails.Action)
	}
}

// MARK: - FungibleTokenList.Action.InternalAction
public extension FungibleTokenList.Action {
	enum InternalAction: Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - FungibleTokenList.Action.ViewAction
public extension FungibleTokenList.Action {
	enum ViewAction: Equatable {}
}

// MARK: - FungibleTokenList.Action.SystemAction
public extension FungibleTokenList.Action {
	enum SystemAction: Equatable {}
}

// MARK: - FungibleTokenList.Action.DelegateAction
public extension FungibleTokenList.Action {
	enum DelegateAction: Equatable {}
}
