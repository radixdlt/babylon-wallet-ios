import ComposableArchitecture
import Foundation

// MARK: - NonFungibleTokenList
/// Namespace for NonFungibleTokenListFeature
public enum NonFungibleTokenList {}

// MARK: NonFungibleTokenList.State
public extension NonFungibleTokenList {
	// MARK: State
	struct State: Equatable {
		public var rows: IdentifiedArrayOf<NonFungibleTokenList.Row.RowState>

		public init(
			rows: IdentifiedArrayOf<NonFungibleTokenList.Row.RowState>
		) {
			self.rows = rows
		}
	}
}
