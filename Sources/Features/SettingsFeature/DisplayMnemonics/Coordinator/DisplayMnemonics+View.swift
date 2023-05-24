import FeaturePrelude

extension DisplayMnemonics.State {
	var viewState: DisplayMnemonics.ViewState {
		.init()
	}
}

// MARK: - DisplayMnemonics.View
extension DisplayMnemonics {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<DisplayMnemonics>

		public init(store: StoreOf<DisplayMnemonics>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				// TODO: implement
				Text("Implement: DisplayMnemonics")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - DisplayMnemonics_Preview
struct DisplayMnemonics_Preview: PreviewProvider {
	static var previews: some View {
		DisplayMnemonics.View(
			store: .init(
				initialState: .previewValue,
				reducer: DisplayMnemonics()
			)
		)
	}
}

extension DisplayMnemonics.State {
	public static let previewValue = Self()
}
#endif
