import Asset
import FungibleTokenListFeature
import NonFungibleTokenListFeature

// MARK: - AssetsView.Action
public extension AssetsView {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
		case fungibleTokenList(FungibleTokenList.Action)
		case nonFungibleTokenList(NonFungibleTokenList.Action)
	}
}

// MARK: - AssetsView.Action.InternalAction
public extension AssetsView.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

// MARK: - AssetsView.Action.InternalAction.UserAction
public extension AssetsView.Action.InternalAction {
	enum UserAction: Equatable {
		case listSelectorTapped(AssetsView.AssetsViewType)
	}
}

// MARK: - AssetsView.Action.InternalAction.SystemAction
public extension AssetsView.Action.InternalAction {
	enum SystemAction: Equatable {}
}

// MARK: - AssetsView.Action.CoordinatingAction
public extension AssetsView.Action {
	enum CoordinatingAction: Equatable {}
}
