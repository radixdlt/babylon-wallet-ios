// MARK: - ConfirmSkippingBDFS.View
extension ConfirmSkippingBDFS {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<ConfirmSkippingBDFS>

		init(store: StoreOf<ConfirmSkippingBDFS>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { _ in
				ScrollView(.vertical, showsIndicators: false) {
					VStack(spacing: .medium2) {
						Text(L10n.RecoverSeedPhrase.Header.titleNoMainSeedPhrase)
							.multilineTextAlignment(.center)
							.textStyle(.sheetTitle)
							.foregroundColor(.primaryText)
							.padding(.horizontal, .large3)

						Text(LocalizedStringKey(L10n.RecoverSeedPhrase.Header.subtitleNoMainSeedPhrase))
							.multilineTextAlignment(.leading)
							.textStyle(.body1Regular)
							.foregroundColor(.primaryText)
							.padding(.horizontal, .large3)

						Button(L10n.RecoverSeedPhrase.skipMainSeedPhraseButton) {
							store.send(.view(.confirmTapped))
						}
						.buttonStyle(.primaryRectangular)
						.padding(.horizontal, .medium3)
					}
					.padding(.bottom, .medium2)
				}
				.toolbar {
					ToolbarItem(placement: .cancellationAction) {
						CloseButton {
							store.send(.view(.closeButtonTapped))
						}
					}
				}
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - ConfirmSkippingBDFS_Preview
struct ConfirmSkippingBDFS_Preview: PreviewProvider {
	static var previews: some View {
		ConfirmSkippingBDFS.View(
			store: .init(
				initialState: .previewValue,
				reducer: ConfirmSkippingBDFS.init
			)
		)
	}
}

extension ConfirmSkippingBDFS.State {
	static let previewValue = Self()
}
#endif
