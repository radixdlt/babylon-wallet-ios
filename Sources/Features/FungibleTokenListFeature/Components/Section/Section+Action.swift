import Asset
import Foundation

// MARK: - FungibleTokenList.Section.Action
public extension FungibleTokenList.Section {
	// MARK: Action
	enum Action: Equatable {
		case child(ChildAction)
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - FungibleTokenList.Section.Action.ChildAction
public extension FungibleTokenList.Section.Action {
	enum ChildAction: Equatable {
		case asset(id: FungibleTokenContainer.ID, action: FungibleTokenList.Row.Action)
	}
}

// MARK: - FungibleTokenList.Section.Action.ViewAction
public extension FungibleTokenList.Section.Action {
	enum ViewAction: Equatable {}
}

// MARK: - FungibleTokenList.Section.Action.InternalAction
public extension FungibleTokenList.Section.Action {
	enum InternalAction: Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - FungibleTokenList.Section.Action.SystemAction
public extension FungibleTokenList.Section.Action {
	enum SystemAction: Equatable {}
}

// MARK: - FungibleTokenList.Section.Action.DelegateAction
public extension FungibleTokenList.Section.Action {
	enum DelegateAction: Equatable {}
}
