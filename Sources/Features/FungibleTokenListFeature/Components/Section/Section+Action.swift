import FeaturePrelude

// MARK: - FungibleTokenList.Section.Action
extension FungibleTokenList.Section {
	// MARK: Action
	public enum Action: Sendable, Equatable {
		case child(ChildAction)
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - FungibleTokenList.Section.Action.ChildAction
extension FungibleTokenList.Section.Action {
	public enum ChildAction: Sendable, Equatable {
		case asset(id: FungibleTokenContainer.ID, action: FungibleTokenList.Row.Action)
	}
}

// MARK: - FungibleTokenList.Section.Action.ViewAction
extension FungibleTokenList.Section.Action {
	public enum ViewAction: Sendable, Equatable {}
}

// MARK: - FungibleTokenList.Section.Action.InternalAction
extension FungibleTokenList.Section.Action {
	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - FungibleTokenList.Section.Action.SystemAction
extension FungibleTokenList.Section.Action {
	public enum SystemAction: Sendable, Equatable {}
}

// MARK: - FungibleTokenList.Section.Action.DelegateAction
extension FungibleTokenList.Section.Action {
	public enum DelegateAction: Sendable, Equatable {}
}
