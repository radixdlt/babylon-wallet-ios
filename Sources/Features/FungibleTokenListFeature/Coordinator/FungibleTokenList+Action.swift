import FeaturePrelude
import FungibleTokenDetailsFeature

// MARK: - FungibleTokenList.Action
public extension FungibleTokenList {
	// MARK: Action
	enum Action: Sendable, Equatable {
		case child(ChildAction)
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - FungibleTokenList.Action.ChildAction
public extension FungibleTokenList.Action {
	enum ChildAction: Sendable, Equatable {
		case section(id: FungibleTokenCategory.CategoryType, action: FungibleTokenList.Section.Action)
		case details(FungibleTokenDetails.Action)
	}
}

// MARK: - FungibleTokenList.Action.InternalAction
public extension FungibleTokenList.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
	}
}

// MARK: - FungibleTokenList.Action.ViewAction
public extension FungibleTokenList.Action {
	enum ViewAction: Sendable, Equatable {
		case selectedTokenChanged(FungibleTokenContainer?)
	}
}

// MARK: - FungibleTokenList.Action.DelegateAction
public extension FungibleTokenList.Action {
	enum DelegateAction: Sendable, Equatable {}
}
