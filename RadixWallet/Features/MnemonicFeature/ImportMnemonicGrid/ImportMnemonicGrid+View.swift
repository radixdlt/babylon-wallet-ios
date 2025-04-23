import SwiftUI

// MARK: - ImportMnemonicGrid.View
extension ImportMnemonicGrid {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<ImportMnemonicGrid>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				VStack(spacing: .medium3) {
					wordPicker

					#if DEBUG
					debugSection
					#endif

					LazyVGrid(columns: .init(repeating: .init(.flexible()), count: 3)) {
						ForEachStore(store.scope(state: \.words, action: { .child(.word($0, $1)) })) {
							ImportMnemonicWord.View(store: $0)
						}
					}
				}
				.multilineTextAlignment(.leading)
				.animation(.default, value: store.wordCount)
				.onAppear {
					store.send(.view(.appeared))
				}
			}
		}

		@ViewBuilder
		private var wordPicker: some SwiftUI.View {
			if !store.isWordCountFixed {
				VStack(spacing: .small1) {
					let label = L10n.ImportMnemonic.numberOfWordsPicker
					Text(label)
						.textStyle(.body1HighImportance)
						.foregroundStyle(.app.gray1)

					Picker(label, selection: $store.wordCount.sending(\.view.wordCountChanged)) {
						ForEach(BIP39WordCount.allCases, id: \.self) { wordCount in
							Text("\(wordCount.rawValue)")
								.textStyle(.body1Regular)
						}
					}
					.pickerStyle(.segmented)
				}
			}
		}

		#if DEBUG
		private var debugSection: some SwiftUI.View {
			VStack(spacing: .small1) {
				Button("DEBUG Paste") {
					store.send(.view(.debugPaste))
				}

				Button("DEBUG Sample") {
					store.send(.view(.debugSetSample))
				}
			}
			.buttonStyle(.secondaryRectangular(shouldExpand: true, isDestructive: true))
		}
		#endif
	}
}
