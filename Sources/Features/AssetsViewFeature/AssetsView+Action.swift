import FeaturePrelude
import FungibleTokenListFeature
import NonFungibleTokenListFeature

public extension AssetsView {
	enum ViewAction: Sendable, Equatable {
		case listSelectorTapped(AssetsView.AssetsViewType)
	}

	enum ChildAction: Sendable, Equatable {
		case fungibleTokenList(FungibleTokenList.Action)
		case nonFungibleTokenList(NonFungibleTokenList.Action)
	}
}
