import Asset
import Foundation

// MARK: - FungibleTokenList.Row.Action
public extension FungibleTokenList.Row {
	// MARK: Action
	enum Action: Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - FungibleTokenList.Row.Action.ViewAction
public extension FungibleTokenList.Row.Action {
	enum ViewAction: Equatable {
		case selected
	}
}

// MARK: - FungibleTokenList.Row.Action.InternalAction
public extension FungibleTokenList.Row.Action {
	enum InternalAction: Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - FungibleTokenList.Row.Action.SystemAction
public extension FungibleTokenList.Row.Action {
	enum SystemAction: Equatable {}
}

// MARK: - FungibleTokenList.Row.Action.DelegateAction
public extension FungibleTokenList.Row.Action {
	enum DelegateAction: Equatable {
		case selected(FungibleTokenContainer)
	}
}
