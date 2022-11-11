import ComposableArchitecture
import Foundation

// MARK: NonFungibleTokenList.State
public extension NonFungibleTokenList {
	// MARK: State
	struct State: Equatable {
		public var rows: IdentifiedArrayOf<NonFungibleTokenList.Row.State>

		public init(
			rows: IdentifiedArrayOf<NonFungibleTokenList.Row.State>
		) {
			self.rows = rows
		}
	}
}
