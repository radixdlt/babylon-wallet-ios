import ComposableArchitecture
import SwiftUI
extension DisplayMnemonic.State {
	var viewState: DisplayMnemonic.ViewState {
		.init(
			isLoading: importMnemonic == nil
		)
	}
}

// MARK: - DisplayMnemonic.View
extension DisplayMnemonic {
	public struct ViewState: Equatable {
		let isLoading: Bool
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<DisplayMnemonic>

		public init(store: StoreOf<DisplayMnemonic>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				if viewStore.isLoading {
					Color
						.white
						.onFirstTask { @MainActor in
							await viewStore.send(.onFirstTask).finish()
						}
				} else {
					IfLetStore(
						store.scope(
							state: \.importMnemonic,
							action: { .child(.importMnemonic($0)) }
						)
					) { importMnemonicViewStore in
						ImportMnemonic.View(store: importMnemonicViewStore)
					}
				}
			}
			.navigationTitle(L10n.RevealSeedPhrase.title)
			.navigationBarTitleDisplayMode(.inline)
		}
	}
}

// #if DEBUG
// import SwiftUI
import ComposableArchitecture //
//// MARK: - DisplayMnemonic_Preview
// struct DisplayMnemonic_Preview: PreviewProvider {
//	static var previews: some View {
//		DisplayMnemonic.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: DisplayMnemonic.init
//			)
//		)
//	}
// }
//
// extension DisplayMnemonic.State {
//	public static let previewValue = Self()
// }
// #endif
