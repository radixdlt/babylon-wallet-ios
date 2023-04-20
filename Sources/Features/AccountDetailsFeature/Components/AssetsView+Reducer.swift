import FeaturePrelude

public struct AssetsView: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		/// All of the possible asset list
		public enum AssetList: Sendable, Hashable, Identifiable {
			public var id: Self {
				self
			}

			case fungibleTokens(FungibleTokenList.State)
			case nonFungibleTokens(NonFungibleTokenList.State)

			var displayName: String {
				switch self {
				case .fungibleTokens:
					return L10n.AssetsView.tokens
				case .nonFungibleTokens:
					return L10n.AssetsView.nfts
				}
			}
		}

		/// The list of Assets to can be shown.
		public var assets: NonEmpty<OrderedSet<AssetList>>

		// Currently active list that is being shown
		public var activeList: AssetList

		public init(
			assets: NonEmpty<OrderedSet<AssetList>>
		) {
			self.assets = assets
			self.activeList = assets.first
		}

		public static func defaultEmpty() -> Self {
			.init(assets:
				.init(rawValue:
					[
						.fungibleTokens(.init()),
						.nonFungibleTokens(.init(rows: [])),
					]
				)!
			)
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case didSelectList(State.AssetList)
	}

	public enum ChildAction: Sendable, Equatable {
		case fungibleTokenList(FungibleTokenList.Action)
		case nonFungibleTokenList(NonFungibleTokenList.Action)
	}

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.activeList, action: /Action.self) {
			EmptyReducer()
				.ifCaseLet(
					/State.AssetList.fungibleTokens,
					action: /Action.child .. ChildAction.fungibleTokenList
				) {
					FungibleTokenList()
				}
				.ifCaseLet(
					/State.AssetList.nonFungibleTokens,
					action: /Action.child .. ChildAction.nonFungibleTokenList
				) {
					NonFungibleTokenList()
				}
		}
		Reduce(self.core)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .didSelectList(assetList):
			state.activeList = assetList
			return .none
		}
	}
}
