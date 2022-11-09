import Asset
import FungibleTokenListFeature
import NonFungibleTokenListFeature

// MARK: - AssetsView.Action
public extension AssetsView {
	// MARK: Action
	enum Action: Equatable {
		case child(ChildAction)
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - AssetsView.Action.ChildAction
public extension AssetsView.Action {
	enum ChildAction: Equatable {
		case fungibleTokenList(FungibleTokenList.Action)
		case nonFungibleTokenList(NonFungibleTokenList.Action)
	}
}

// MARK: - AssetsView.Action.ViewAction
public extension AssetsView.Action {
	enum ViewAction: Equatable {
		case listSelectorTapped(AssetsView.AssetsViewType)
	}
}

// MARK: - AssetsView.Action.InternalAction
public extension AssetsView.Action {
	enum InternalAction: Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - AssetsView.Action.InternalAction.SystemAction
public extension AssetsView.Action.InternalAction {
	enum SystemAction: Equatable {}
}

// MARK: - AssetsView.Action.DelegateAction
public extension AssetsView.Action {
	enum DelegateAction: Equatable {}
}
