import SwiftUI

// MARK: - DisplayMnemonic.View
extension DisplayMnemonic {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<DisplayMnemonic>

		init(store: StoreOf<DisplayMnemonic>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack(spacing: .medium1) {
						Text(L10n.ConfirmMnemonicBackedUp.subtitle)
							.foregroundStyle(.app.gray1)
							.textStyle(.body1Regular)
							.multilineTextAlignment(.center)

						wordsGrid()

						Button(L10n.Common.done) {
							store.send(.view(.doneViewingButtonTapped))
						}
						.buttonStyle(.primaryRectangular)
					}
					.padding(.horizontal, .medium2)
					.padding(.bottom, .large3)
				}
				.scrollIndicators(.hidden)
				.destinations(with: store)
			}
			.radixToolbar(title: L10n.ConfirmMnemonicBackedUp.title)
		}

		@ViewBuilder
		private func wordsGrid() -> some SwiftUI.View {
			SwiftUI.Grid(horizontalSpacing: .small2, verticalSpacing: .medium1) {
				ForEach(Array(store.words.chunks(ofCount: 3).enumerated()), id: \.offset) { _, row in
					GridRow {
						ForEach(row) { word in
							VStack {
								wordBox(word)
							}
						}
					}
				}
			}
		}

		@ViewBuilder
		private func wordBox(_ word: OffsetIdentified<BIP39Word>) -> some SwiftUI.View {
			AppTextField(
				primaryHeading: .init(
					text: L10n.ImportMnemonic.wordHeading(word.offset + 1),
					isProminent: true
				),
				placeholder: "",
				text: .constant(word.element.word),
			)
			.disabled(true)
			.minimumScaleFactor(0.9)
		}
	}
}

private extension StoreOf<DisplayMnemonic> {
	var destination: PresentationStoreOf<DisplayMnemonic.Destination> {
		scope(state: \.$destination, action: \.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<DisplayMnemonic>) -> some View {
		let destinationStore = store.destination
		return backupConfirmation(with: destinationStore)
			.verifyMnemonic(with: destinationStore)
	}

	private func backupConfirmation(with destinationStore: PresentationStoreOf<DisplayMnemonic.Destination>) -> some View {
		alert(store: destinationStore.scope(state: \.backupConfirmation, action: \.backupConfirmation))
	}

	private func verifyMnemonic(with destinationStore: PresentationStoreOf<DisplayMnemonic.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.verifyMnemonic, action: \.verifyMnemonic)) {
			VerifyMnemonic.View(store: $0)
		}
	}
}
