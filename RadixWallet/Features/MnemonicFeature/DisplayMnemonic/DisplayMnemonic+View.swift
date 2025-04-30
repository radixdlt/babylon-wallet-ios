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
						StatusMessageView(text: L10n.RevealSeedPhrase.warning, type: .warning)

						#if DEBUG
						debugSection
						#endif

						wordsGrid()

						Button(L10n.Common.done) {
							store.send(.view(.doneViewingButtonTapped))
						}
						.buttonStyle(.primaryRectangular)
					}
					.padding([.horizontal, .top], .medium2)
					.padding(.bottom, .large3)
				}
				.scrollIndicators(.hidden)
				.destinations(with: store)
				.navigationBarBackButtonHidden(true) // need to be able to hook "back" button press
				.toolbar {
					ToolbarItem(placement: .navigationBarLeading) {
						BackButton {
							store.send(.view(.backButtonTapped))
						}
					}
				}
			}
			.background(Color.primaryBackground)
			.radixToolbar(title: L10n.RevealSeedPhrase.title)
		}

		@ViewBuilder
		private func wordsGrid() -> some SwiftUI.View {
			SwiftUI.Grid(horizontalSpacing: .small2, verticalSpacing: .medium1) {
				ForEach(Array(store.words.chunks(ofCount: 3).enumerated()), id: \.offset) { _, row in
					GridRow {
						ForEach(row) { word in
							wordBox(word)
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
				preventScreenshot: true,
			)
			.allowsHitTesting(false)
			.minimumScaleFactor(0.9)
		}

		#if DEBUG
		private var debugSection: some SwiftUI.View {
			VStack(spacing: .small1) {
				Button("DEBUG Copy") {
					store.send(.view(.debugCopy))
				}
			}
			.buttonStyle(.secondaryRectangular(shouldExpand: true, isDestructive: true))
		}
		#endif
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
