import Common
import ComposableArchitecture
import FungibleTokenListFeature

// MARK: - AssetsView
/// Namespace for AssetsViewFeature
public enum AssetsView {}

// MARK: AssetsView.State
public extension AssetsView {
	// MARK: State
	struct State: Equatable {
		public var type: AssetsViewType = .tokens
		public var fungibleTokenList: FungibleTokenList.State

		public init(
			fungibleTokenList: FungibleTokenList.State
		) {
			self.fungibleTokenList = fungibleTokenList
		}
	}
}

// MARK: AssetsView.AssetsViewType
public extension AssetsView {
	enum AssetsViewType: String, CaseIterable, Identifiable {
		case tokens
		case nfts
		case poolShare
		case badges

		var displayText: String {
			switch self {
			case .tokens:
				return L10n.AssetList.tokens
			case .nfts:
				return L10n.AssetList.nfts
			case .poolShare:
				return L10n.AssetList.poolShare
			case .badges:
				return L10n.AssetList.badges
			}
		}
	}
}
