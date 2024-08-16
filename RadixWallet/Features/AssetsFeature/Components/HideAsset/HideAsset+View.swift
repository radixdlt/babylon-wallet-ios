
// MARK: - HideAsset.View
public extension HideAsset {
	struct View: SwiftUI.View {
		private let store: StoreOf<HideAsset>

		public init(store: StoreOf<HideAsset>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithPerceptionTracking {
				if store.shouldShow {
					Button(L10n.AssetDetails.HideAsset.button) {
						store.send(.view(.buttonTapped))
					}
					.buttonStyle(.secondaryRectangular(shouldExpand: true))
					.padding(.horizontal, .medium3)
				}
			}
			.task {
				await store.send(.view(.task)).finish()
			}
		}
	}
}
