import FeaturePrelude

// MARK: - FungibleTokenList.Section.Action
public extension FungibleTokenList.Section {
	// MARK: Action
	enum Action: Sendable, Equatable {
		case child(ChildAction)
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - FungibleTokenList.Section.Action.ChildAction
public extension FungibleTokenList.Section.Action {
	enum ChildAction: Sendable, Equatable {
		case asset(id: FungibleTokenContainer.ID, action: FungibleTokenList.Row.Action)
	}
}

// MARK: - FungibleTokenList.Section.Action.ViewAction
public extension FungibleTokenList.Section.Action {
	enum ViewAction: Sendable, Equatable {}
}

// MARK: - FungibleTokenList.Section.Action.InternalAction
public extension FungibleTokenList.Section.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - FungibleTokenList.Section.Action.SystemAction
public extension FungibleTokenList.Section.Action {
	enum SystemAction: Sendable, Equatable {}
}

// MARK: - FungibleTokenList.Section.Action.DelegateAction
public extension FungibleTokenList.Section.Action {
	enum DelegateAction: Sendable, Equatable {}
}
