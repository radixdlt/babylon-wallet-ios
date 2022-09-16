import Asset
import Foundation

// MARK: - NonFungibleTokenList.Row
/// Namespace for Row
public extension NonFungibleTokenList {
	enum Row {}
}

// MARK: - NonFungibleTokenList.Row.RowState
public extension NonFungibleTokenList.Row {
	// MARK: State
	struct RowState: Equatable {
		public var containers: [NonFungibleTokenContainer]
		public var isExpanded = false

		public init(
			containers: [NonFungibleTokenContainer]
		) {
			self.containers = containers
		}
	}
}

// MARK: - NonFungibleTokenList.Row.RowState + Identifiable
extension NonFungibleTokenList.Row.RowState: Identifiable {
	public var id: NonFungibleTokenContainer.ID { containers.first?.id ?? "" }
}
