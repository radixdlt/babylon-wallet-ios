import FeaturePrelude

// MARK: - MessageMode.View
extension MessageMode {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<MessageMode>

		public init(store: StoreOf<MessageMode>) {
			self.store = store
		}
	}
}

extension MessageMode.View {
	public var body: some View {
		WithViewStore(store, observe: { $0 }, send: { .view($0) }) { _ in
			Text("MESSAGE MODE: TODO IMPLEMENT").textStyle(.sheetTitle)
		}
	}
}
