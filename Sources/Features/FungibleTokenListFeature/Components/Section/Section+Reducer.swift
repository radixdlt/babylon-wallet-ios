import FeaturePrelude

extension FungibleTokenList {
	public struct Section: Sendable, FeatureReducer {
		public struct State: Sendable, Hashable, Identifiable {
			public let id: FungibleTokenCategory.CategoryType
			public var assets: IdentifiedArrayOf<FungibleTokenList.Row.State>

			public init(
				id: FungibleTokenCategory.CategoryType,
				assets: IdentifiedArrayOf<FungibleTokenList.Row.State>
			) {
				self.id = id
				self.assets = assets
			}
		}

		public enum ChildAction: Sendable, Equatable {
			case asset(id: FungibleTokenContainer.ID, action: FungibleTokenList.Row.Action)
		}

		public init() {}

		public var body: some ReducerProtocolOf<Self> {
			Reduce(core)
                                .forEach(\.assets, action: /Action.child .. ChildAction.asset) {
					FungibleTokenList.Row()
				}
		}
	}
}
