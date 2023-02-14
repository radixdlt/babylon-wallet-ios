import FeaturePrelude

// MARK: - FungibleTokenList.Row.Action
extension FungibleTokenList.Row {
	// MARK: Action
	public enum Action: Sendable, Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - FungibleTokenList.Row.Action.ViewAction
extension FungibleTokenList.Row.Action {
	public enum ViewAction: Sendable, Equatable {
		case selected
	}
}

// MARK: - FungibleTokenList.Row.Action.InternalAction
extension FungibleTokenList.Row.Action {
	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - FungibleTokenList.Row.Action.SystemAction
extension FungibleTokenList.Row.Action {
	public enum SystemAction: Sendable, Equatable {}
}

// MARK: - FungibleTokenList.Row.Action.DelegateAction
extension FungibleTokenList.Row.Action {
	public enum DelegateAction: Sendable, Equatable {
		case selected(FungibleTokenContainer)
	}
}
