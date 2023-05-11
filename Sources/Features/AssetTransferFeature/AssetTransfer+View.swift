import FeaturePrelude

extension AssetTransfer.State {
	var viewState: AssetTransfer.ViewState {
		.init()
	}
}

extension AssetTransfer {
	public struct ViewState: Equatable {
		// TODO: Add
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AssetTransfer>

		public init(store: StoreOf<AssetTransfer>) {
			self.store = store
		}
	}
}

extension AssetTransfer.View {
	public var body: some View {
		WithViewStore(store, observe: \.viewState) { _ in
			Text("TODO: IMPLEMENT")
		}
	}
}
