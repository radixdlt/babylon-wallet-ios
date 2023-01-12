import FeaturePrelude

// MARK: - NonFungibleTokenList.Row.State
public extension NonFungibleTokenList.Row {
	// MARK: State
	struct State: Sendable, Equatable {
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

#if DEBUG
public extension NonFungibleTokenList.Row.State {
	static let previewValue = Self(
		container: .mock1
	)
}
#endif
