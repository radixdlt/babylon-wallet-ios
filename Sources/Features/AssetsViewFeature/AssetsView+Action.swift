import FeaturePrelude
import FungibleTokenListFeature
import NonFungibleTokenListFeature

extension AssetsView {
	public enum ViewAction: Sendable, Equatable {
		case listSelectorTapped(AssetsView.AssetsViewType)
	}

	public enum ChildAction: Sendable, Equatable {
		case fungibleTokenList(FungibleTokenList.Action)
		case nonFungibleTokenList(NonFungibleTokenList.Action)
	}
}
