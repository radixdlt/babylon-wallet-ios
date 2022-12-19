import Asset
import ComposableArchitecture
import Foundation

// MARK: NonFungibleTokenList.State
public extension NonFungibleTokenList {
	// MARK: State
	struct State: Equatable {
		public var rows: IdentifiedArrayOf<NonFungibleTokenList.Row.State>
		public var selectedToken: NonFungibleTokenContainer?

		public init(
			rows: IdentifiedArrayOf<NonFungibleTokenList.Row.State>,
			selectedToken: NonFungibleTokenContainer? = nil
		) {
			self.rows = rows
			self.selectedToken = selectedToken
		}
	}
}
