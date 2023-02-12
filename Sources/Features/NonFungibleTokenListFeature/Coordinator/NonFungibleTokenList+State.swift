import FeaturePrelude

// MARK: NonFungibleTokenList.State
extension NonFungibleTokenList {
	// MARK: State
	public struct State: Sendable, Hashable {
		public var rows: IdentifiedArrayOf<NonFungibleTokenList.Row.State>
		public var selectedToken: NonFungibleTokenList.Detail.State?

		public init(
			rows: IdentifiedArrayOf<NonFungibleTokenList.Row.State>,
			selectedToken: NonFungibleTokenList.Detail.State? = nil
		) {
			self.rows = rows
			self.selectedToken = selectedToken
		}
	}
}
