import FeaturePrelude

// MARK: FungibleTokenList.State
extension FungibleTokenList {
	// MARK: State
	public struct State: Sendable, Hashable {
		public var sections: IdentifiedArrayOf<FungibleTokenList.Section.State>
		public var selectedToken: FungibleTokenContainer?

		public init(
			sections: IdentifiedArrayOf<FungibleTokenList.Section.State>,
			selectedToken: FungibleTokenContainer? = nil
		) {
			self.sections = sections
			self.selectedToken = selectedToken
		}
	}
}
