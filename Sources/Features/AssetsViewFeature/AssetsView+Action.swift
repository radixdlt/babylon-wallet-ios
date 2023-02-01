import FeaturePrelude
import FungibleTokenListFeature
import NonFungibleTokenListFeature

public extension AssetsView {
	typealias Action = ActionOf<Self>

	enum ViewAction: Sendable, Equatable {
		case listSelectorTapped(AssetsView.AssetsViewType)
	}

	enum InternalAction: Sendable, Equatable {}

	enum ChildAction: Sendable, Equatable {
		case fungibleTokenList(FungibleTokenList.Action)
		case nonFungibleTokenList(NonFungibleTokenList.Action)
	}

	enum DelegateAction: Sendable, Equatable {}
}
