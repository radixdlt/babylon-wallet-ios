import Common
import ComposableArchitecture
import FungibleTokenListFeature
import NonFungibleTokenListFeature

// MARK: - AssetsView.State
public extension AssetsView {
	// MARK: State
	struct State: Equatable {
		public var type: AssetsViewType = .tokens
		public var fungibleTokenList: FungibleTokenList.State
		public var nonFungibleTokenList: NonFungibleTokenList.State

		public init(
			fungibleTokenList: FungibleTokenList.State,
			nonFungibleTokenList: NonFungibleTokenList.State
		) {
			self.fungibleTokenList = fungibleTokenList
			self.nonFungibleTokenList = nonFungibleTokenList
		}
	}
}

// MARK: - AssetsView.AssetsViewType
public extension AssetsView {
	enum AssetsViewType: String, CaseIterable, Identifiable {
		case tokens
		case nfts

		// TODO: uncomment when ready for implementation
		/*
		 case poolShare
		 case badges
		 */

		var displayText: String {
			switch self {
			case .tokens:
				return L10n.AssetsView.tokens
			case .nfts:
				return L10n.AssetsView.nfts

				// TODO: uncomment when ready for implementation
				/*
				 case .poolShare:
				 	return L10n.AssetsView.poolShare
				 case .badges:
				 	return L10n.AssetsView.badges
				 */
			}
		}
	}
}
