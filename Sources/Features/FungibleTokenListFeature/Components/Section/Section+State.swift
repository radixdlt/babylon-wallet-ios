import FeaturePrelude

// MARK: - FungibleTokenList.Section.State
extension FungibleTokenList.Section {
	// MARK: State
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
}
