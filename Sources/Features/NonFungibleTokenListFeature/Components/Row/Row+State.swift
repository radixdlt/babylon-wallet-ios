import Asset
import Foundation

// MARK: - NonFungibleTokenList.Row.State
public extension NonFungibleTokenList.Row {
	// MARK: State
	struct State: Equatable {
		public var containers: [NonFungibleTokenContainer]
		public var isExpanded = false

		public init(
			containers: [NonFungibleTokenContainer]
		) {
			self.containers = containers
		}
	}
}

// MARK: - NonFungibleTokenList.Row.State + Identifiable
extension NonFungibleTokenList.Row.State: Identifiable {
	public var id: NonFungibleTokenContainer.ID { containers.first?.id ?? "" }
}
