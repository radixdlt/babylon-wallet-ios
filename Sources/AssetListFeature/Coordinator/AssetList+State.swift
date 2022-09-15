import Common
import ComposableArchitecture

// MARK: - AssetList
/// Namespace for AssetListFeature
public enum AssetList {}

public extension AssetList {
	// MARK: State
	struct State: Equatable {
		public var type: ListType = .tokens
		public var sections: IdentifiedArrayOf<AssetList.Section.State>

		public init(
			sections: IdentifiedArrayOf<AssetList.Section.State>
		) {
			self.sections = sections
		}
	}
}

public extension AssetList {
	enum ListType: String, CaseIterable, Identifiable {
		case tokens
		case nfts
		case poolShare
		case badges

		var displayText: String {
			switch self {
			case .tokens:
				return L10n.Home.AssetList.tokens
			case .nfts:
				return L10n.Home.AssetList.nfts
			case .poolShare:
				return L10n.Home.AssetList.poolShare
			case .badges:
				return L10n.Home.AssetList.badges
			}
		}
	}
}
