import FeaturePrelude

// MARK: - AddAsset.View
extension AddAsset {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AddAsset>

		public init(store: StoreOf<AddAsset>) {
			self.store = store
		}
	}
}

extension AddAsset.View {
	public var body: some View {
		WithViewStore(store, observe: { $0 }, send: { .view($0) }) { _ in
			Text("ADD ASSET: TODO IMPLEMENT").textStyle(.sheetTitle)
		}
	}
}
