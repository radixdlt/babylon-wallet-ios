import FeaturePrelude

// MARK: - NonFungibleTokenList.Row.State
extension NonFungibleTokenList.Row {
	// MARK: State
	public struct State: Sendable, Hashable {
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
extension NonFungibleTokenList.Row.State {
	public static let previewValue = Self(
		container: .mock1
	)
}
#endif
