import Asset
import ComposableArchitecture

// MARK: - FungibleTokenList.Section.State
public extension FungibleTokenList.Section {
	// MARK: State
	struct State: Equatable, Identifiable {
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
