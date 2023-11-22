extension ConfirmSkippingBDFS.State {
	var viewState: ConfirmSkippingBDFS.ViewState {
		.init(flashScrollIndicators: flashScrollIndicators)
	}
}

// MARK: - ConfirmSkippingBDFS.View
extension ConfirmSkippingBDFS {
	public struct ViewState: Equatable {
		let flashScrollIndicators: Bool
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ConfirmSkippingBDFS>

		public init(store: StoreOf<ConfirmSkippingBDFS>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: .medium2) {
					Text(L10n.RecoverSeedPhrase.Header.titleNoMainSeedPhrase)
						.textStyle(.sheetTitle)
						.foregroundColor(.app.gray1)
						.multilineTextAlignment(.center)

					ScrollView(.vertical, showsIndicators: true) {
						// Contains bold text segments.
						Text(LocalizedStringKey(L10n.RecoverSeedPhrase.Header.subtitleNoMainSeedPhrase))
							.textStyle(.body1Regular)
							.foregroundColor(.app.gray1)
							.multilineTextAlignment(.leading)
					}
					.modifier {
						if #available(iOS 17, *) {
							$0.scrollIndicatorsFlash(trigger: viewStore.flashScrollIndicators)
						} else {
							$0
						}
					}

					Button(L10n.RecoverSeedPhrase.skipMainSeedPhraseButton) {
						store.send(.view(.confirmTapped))
					}
					.buttonStyle(.primaryRectangular)
				}
				.task { @MainActor in
					await store.send(.view(.task)).finish()
				}
				.padding(.horizontal, .large3)
				.padding(.bottom, .medium2)
				.toolbar {
					ToolbarItem(placement: .primaryAction) {
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
	public static let previewValue = Self()
}
#endif
