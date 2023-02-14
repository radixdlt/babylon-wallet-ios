import FeaturePrelude
import FungibleTokenDetailsFeature

// MARK: - FungibleTokenList.Action
extension FungibleTokenList {
	// MARK: Action
	public enum Action: Sendable, Equatable {
		case child(ChildAction)
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - FungibleTokenList.Action.ChildAction
extension FungibleTokenList.Action {
	public enum ChildAction: Sendable, Equatable {
		case section(id: FungibleTokenCategory.CategoryType, action: FungibleTokenList.Section.Action)
		case details(FungibleTokenDetails.Action)
	}
}

// MARK: - FungibleTokenList.Action.InternalAction
extension FungibleTokenList.Action {
	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
	}
}

// MARK: - FungibleTokenList.Action.ViewAction
extension FungibleTokenList.Action {
	public enum ViewAction: Sendable, Equatable {
		case selectedTokenChanged(FungibleTokenContainer?)
	}
}

// MARK: - FungibleTokenList.Action.DelegateAction
extension FungibleTokenList.Action {
	public enum DelegateAction: Sendable, Equatable {}
}
