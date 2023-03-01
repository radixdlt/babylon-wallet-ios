import FeaturePrelude

// MARK: NonFungibleTokenList.State
extension NonFungibleTokenList {
	// MARK: State
	public struct State: Sendable, Hashable {
		public var rows: IdentifiedArrayOf<NonFungibleTokenList.Row.State>

		@PresentationState
		public var destination: Destinations.State?

		public init(rows: IdentifiedArrayOf<NonFungibleTokenList.Row.State>) {
			self.rows = rows
		}
	}
}
