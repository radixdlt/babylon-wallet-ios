import ComposableArchitecture
import SwiftUI

// MARK: - MessageMode.View
extension MessageMode {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<MessageMode>

		init(store: StoreOf<MessageMode>) {
			self.store = store
		}
	}
}

extension MessageMode.View {
	var body: some View {
		WithViewStore(store, observe: { $0 }, send: { .view($0) }) { _ in
			Text("MESSAGE MODE: TODO IMPLEMENT").textStyle(.sheetTitle)
		}
	}
}
