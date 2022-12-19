import Asset
import Foundation

// MARK: - NonFungibleTokenList.Action
public extension NonFungibleTokenList {
	// MARK: Action
	enum Action: Equatable {
		case child(ChildAction)
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - NonFungibleTokenList.Action.ChildAction
public extension NonFungibleTokenList.Action {
	enum ChildAction: Equatable {
		case asset(id: NonFungibleTokenContainer.ID, action: NonFungibleTokenList.Row.Action)
		case details(NonFungibleTokenList.Detail.Action)
	}
}

// MARK: - NonFungibleTokenList.Action.ViewAction
public extension NonFungibleTokenList.Action {
	enum ViewAction: Equatable {
		case selectedTokenChanged(NonFungibleTokenContainer?)
	}
}

// MARK: - NonFungibleTokenList.Action.InternalAction
public extension NonFungibleTokenList.Action {
	enum InternalAction: Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - NonFungibleTokenList.Action.SystemAction
public extension NonFungibleTokenList.Action {
	enum SystemAction: Equatable {}
}

// MARK: - NonFungibleTokenList.Action.DelegateAction
public extension NonFungibleTokenList.Action {
	enum DelegateAction: Equatable {}
}
