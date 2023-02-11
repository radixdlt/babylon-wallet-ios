import FeaturePrelude

// MARK: - NonFungibleTokenList.Row.Action
extension NonFungibleTokenList.Row {
	// MARK: Action
	public enum Action: Sendable, Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - NonFungibleTokenList.Row.Action.ViewAction
extension NonFungibleTokenList.Row.Action {
	public enum ViewAction: Sendable, Equatable {
		case isExpandedToggled
		case selected(NonFungibleTokenList.Detail.State)
	}
}

// MARK: - NonFungibleTokenList.Row.Action.InternalAction
extension NonFungibleTokenList.Row.Action {
	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - NonFungibleTokenList.Row.Action.SystemAction
extension NonFungibleTokenList.Row.Action {
	public enum SystemAction: Sendable, Equatable {}
}

// MARK: - NonFungibleTokenList.Row.Action.DelegateAction
extension NonFungibleTokenList.Row.Action {
	public enum DelegateAction: Sendable, Equatable {
		case selected(NonFungibleTokenList.Detail.State)
	}
}
