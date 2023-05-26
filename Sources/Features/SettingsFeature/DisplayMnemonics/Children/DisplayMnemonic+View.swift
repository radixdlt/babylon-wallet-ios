import FeaturePrelude

extension DisplayMnemonic.State {
	var viewState: DisplayMnemonic.ViewState {
		.init()
	}
}

// MARK: - DisplayMnemonic.View
extension DisplayMnemonic {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<DisplayMnemonic>

		public init(store: StoreOf<DisplayMnemonic>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in

				Text("Loading mnemonic...")
					.onFirstTask { @MainActor in
						await viewStore.send(.onFirstTask).finish()
					}
			}
		}
	}
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - DisplayMnemonic_Preview
// struct DisplayMnemonic_Preview: PreviewProvider {
//	static var previews: some View {
//		DisplayMnemonic.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: DisplayMnemonic()
//			)
//		)
//	}
// }
//
// extension DisplayMnemonic.State {
//	public static let previewValue = Self()
// }
// #endif
