import Asset
import Foundation

// MARK: - NonFungibleTokenList.Row.State
public extension NonFungibleTokenList.Row {
	// MARK: State
	struct State: Equatable {
		public var container: NonFungibleTokenContainer
		public var isExpanded = false

		public init(
			container: NonFungibleTokenContainer
		) {
			self.container = container
		}
	}
}

// MARK: - NonFungibleTokenList.Row.State + Identifiable
extension NonFungibleTokenList.Row.State: Identifiable {
	public var id: NonFungibleTokenContainer.ID { container.id }
}
