import FeaturePrelude

public struct AssetsView: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		/// All of the possible asset list
		public enum AssetKind: String, Sendable, Hashable, CaseIterable, Identifiable {
			case tokens
			case nfts

			var displayText: String {
				switch self {
				case .tokens:
					return L10n.AssetsView.tokens
				case .nfts:
					return L10n.AssetsView.nfts
				}
			}
		}

		public var activeAssetKind: AssetKind
		public var assetKinds: NonEmpty<[AssetKind]>
		public var fungibleTokenList: FungibleTokenList.State
		public var nonFungibleTokenList: NonFungibleTokenList.State

		public init(
			assetKinds: NonEmpty<[AssetKind]> = .init([.tokens, .nfts])!,
			fungibleTokenList: FungibleTokenList.State,
			nonFungibleTokenList: NonFungibleTokenList.State
		) {
			self.assetKinds = assetKinds
			self.activeAssetKind = assetKinds.first
			self.fungibleTokenList = fungibleTokenList
			self.nonFungibleTokenList = nonFungibleTokenList
		}

		public static func defaultEmpty() -> Self {
			.init(fungibleTokenList: .init(), nonFungibleTokenList: .init(rows: []))
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case didSelectList(State.AssetKind)
	}

	public enum ChildAction: Sendable, Equatable {
		case fungibleTokenList(FungibleTokenList.Action)
		case nonFungibleTokenList(NonFungibleTokenList.Action)
	}

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.nonFungibleTokenList, action: /Action.child .. ChildAction.nonFungibleTokenList) {
			NonFungibleTokenList()
		}

		Scope(state: \.fungibleTokenList, action: /Action.child .. ChildAction.fungibleTokenList) {
			FungibleTokenList()
		}
		Reduce(self.core)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .didSelectList(kind):
			state.activeAssetKind = kind
			return .none
		}
	}
}
