import FeaturePrelude

// MARK: - NonFungibleTokenList.Action
extension NonFungibleTokenList {
	// MARK: Action
	public enum Action: Sendable, Equatable {
		case child(ChildAction)
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - NonFungibleTokenList.Action.ChildAction
extension NonFungibleTokenList.Action {
	public enum ChildAction: Sendable, Equatable {
		case asset(id: NonFungibleTokenContainer.ID, action: NonFungibleTokenList.Row.Action)
		case destination(PresentationActionOf<NonFungibleTokenList.Destinations>)
	}
}

// MARK: - NonFungibleTokenList.Action.ViewAction
extension NonFungibleTokenList.Action {
	public enum ViewAction: Sendable, Equatable {
		case selectedTokenChanged(NonFungibleTokenList.Detail.State?)
	}
}

// MARK: - NonFungibleTokenList.Action.InternalAction
extension NonFungibleTokenList.Action {
	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - NonFungibleTokenList.Action.SystemAction
extension NonFungibleTokenList.Action {
	public enum SystemAction: Sendable, Equatable {}
}

// MARK: - NonFungibleTokenList.Action.DelegateAction
extension NonFungibleTokenList.Action {
	public enum DelegateAction: Sendable, Equatable {}
}
