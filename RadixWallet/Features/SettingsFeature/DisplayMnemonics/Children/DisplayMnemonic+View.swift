import ComposableArchitecture
import SwiftUI
extension DisplayMnemonic.State {
	var viewState: DisplayMnemonic.ViewState {
		.init(
			isLoading: exportMnemonic == nil
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
							state: \.exportMnemonic,
							action: { .child(.exportMnemonic($0)) }
						)
					) { exportMnemonicViewStore in
						ExportMnemonic.View(store: exportMnemonicViewStore)
					}
				}
			}
			.navigationTitle(L10n.RevealSeedPhrase.title)
			.navigationBarTitleDisplayMode(.inline)
		}
	}
}
