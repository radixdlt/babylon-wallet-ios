import Asset
import Foundation

// MARK: - NonFungibleTokenList.Row.Action
public extension NonFungibleTokenList.Row {
	// MARK: Action
	enum Action: Sendable, Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - NonFungibleTokenList.Row.Action.ViewAction
public extension NonFungibleTokenList.Row.Action {
	enum ViewAction: Sendable, Equatable {
		case isExpandedToggled
		case selected(NonFungibleTokenList.Detail.State)
	}
}

// MARK: - NonFungibleTokenList.Row.Action.InternalAction
public extension NonFungibleTokenList.Row.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - NonFungibleTokenList.Row.Action.SystemAction
public extension NonFungibleTokenList.Row.Action {
	enum SystemAction: Sendable, Equatable {}
}

// MARK: - NonFungibleTokenList.Row.Action.DelegateAction
public extension NonFungibleTokenList.Row.Action {
	enum DelegateAction: Sendable, Equatable {
		case selected(NonFungibleTokenList.Detail.State)
	}
}
