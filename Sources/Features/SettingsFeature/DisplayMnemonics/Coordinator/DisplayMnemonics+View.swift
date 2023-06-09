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
					VStack(alignment: .leading, spacing: .medium1) {
						Text("A Seed Phrase provides full access to your accounts and funds. When viewing, ensure you’re in a safe environment and no one is looking at your screen.")
							.textStyle(.body1HighImportance)
							.foregroundColor(.app.gray2)
							.multilineTextAlignment(.leading)
							.padding(.horizontal, .medium3)

						WarningView(text: "You are responsible for the security of your Seed Phrase")
							.padding(.horizontal, .medium3)

						ForEachStore(
							store.scope(
								state: \.deviceFactorSources,
								action: { .child(.row(id: $0, action: $1)) }
							)
						) {
							DisplayMnemonicRow.View(store: $0)
								.padding(.medium3)
							Separator()
						}
						.background(.app.background)
					}
					.padding(.top, .medium3)
				}
				.background(.app.gray4)
				.navigationTitle(L10n.DisplayMnemonics.seedPhrases)
				.toolbarBackground(.visible, for: .navigationBar)
				.onFirstTask { @MainActor in
					await viewStore.send(.onFirstTask).finish()
				}
			}
			.destinations(with: store)
		}
	}
}

extension View {
	@MainActor
	fileprivate func destinations(
		with store: StoreOf<DisplayMnemonics>
	) -> some View {
		let destinationStore = store.scope(
			state: \.$destination,
			action: { .child(.destination($0)) }
		)

		return displayMnemonicSheet(with: destinationStore)
	}

	@MainActor
	private func displayMnemonicSheet(with destinationStore: PresentationStoreOf<DisplayMnemonics.Destinations>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /DisplayMnemonics.Destinations.State.displayMnemonic,
			action: DisplayMnemonics.Destinations.Action.displayMnemonic,
			destination: { DisplayMnemonic.View(store: $0) }
		)
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
