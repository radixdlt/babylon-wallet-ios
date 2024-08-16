
// MARK: - HideAsset.View
public extension HideAsset {
	struct View: SwiftUI.View {
		private let store: StoreOf<HideAsset>

		public init(store: StoreOf<HideAsset>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			Button("Hide Asset") {
				store.send(.view(.buttonTapped))
			}
			.buttonStyle(.secondaryRectangular(shouldExpand: true))
			.padding(.horizontal, .medium3)
		}
	}
}
