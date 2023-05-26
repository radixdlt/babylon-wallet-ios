import FeaturePrelude

extension DisplayMnemonics.State {
	var viewState: DisplayMnemonics.ViewState {
		.init()
	}
}

// MARK: - DisplayMnemonics.View
extension DisplayMnemonics {
	public struct ViewState: Equatable {}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<DisplayMnemonics>

		public init(store: StoreOf<DisplayMnemonics>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				ScrollView {
					VStack {
						ForEachStore(
							store.scope(
								state: \.deviceFactorSources,
								action: { .child(.row(id: $0, action: $1)) }
							)
						) {
							DisplayMnemonicRow.View(store: $0)
						}
						.padding()
					}
				}
				// FIXME: strings
				.navigationTitle("Seed phrases")
				.sheet(
					store: store.scope(
						state: \.$displayMnemonic,
						action: { .child(.details($0)) }
					),
					content: {
						DisplayMnemonic.View(store: $0)
					}
				)
				.onFirstTask { @MainActor in
					await viewStore.send(.onFirstTask).finish()
				}
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
