import FeaturePrelude
import FungibleTokenListFeature
import NonFungibleTokenListFeature

// MARK: - AssetsView.Action
public extension AssetsView {
	// MARK: Action
	enum Action: Sendable, Equatable {
		case child(ChildAction)
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - AssetsView.Action.ChildAction
public extension AssetsView.Action {
	enum ChildAction: Sendable, Equatable {
		case fungibleTokenList(FungibleTokenList.Action)
		case nonFungibleTokenList(NonFungibleTokenList.Action)
	}
}

// MARK: - AssetsView.Action.ViewAction
public extension AssetsView.Action {
	enum ViewAction: Sendable, Equatable {
		case listSelectorTapped(AssetsView.AssetsViewType)
	}
}

// MARK: - AssetsView.Action.InternalAction
public extension AssetsView.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - AssetsView.Action.InternalAction.SystemAction
public extension AssetsView.Action.InternalAction {
	enum SystemAction: Sendable, Equatable {}
}

// MARK: - AssetsView.Action.DelegateAction
public extension AssetsView.Action {
	enum DelegateAction: Sendable, Equatable {}
}
