import FeaturePrelude

// MARK: - CreationOfEntity.View
extension CreationOfEntity {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<CreationOfEntity>

		public init(store: StoreOf<CreationOfEntity>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			Color.white
				.onAppear { ViewStore(store.stateless).send(.view(.appeared)) }
		}
	}
}
