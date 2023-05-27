import Cryptography
import FeaturePrelude
#if os(iOS)
import ScreenshotPreventingSwiftUI
#endif

extension ImportMnemonic.State {
	var viewState: ImportMnemonic.ViewState {
		.init(
			isReadonlyMode: isReadonlyMode,
			isHidingSecrets: isHidingSecrets,
			rowCount: rowCount,
			wordCount: wordCount.rawValue,
			isAddRowButtonEnabled: isAddRowButtonEnabled,
			isRemoveRowButtonEnabled: isRemoveRowButtonEnabled,
			completedWords: completedWords,
			mnemonic: mnemonic,
			bip39Passphrase: bip39Passphrase
		)
	}

	var rowCount: Int {
		words.count / ImportMnemonic.wordsPerRow
	}
}

// MARK: - ImportMnemonic.View
extension ImportMnemonic {
	public struct ViewState: Equatable {
		let isReadonlyMode: Bool
		let isHidingSecrets: Bool
		let rowCount: Int
		let wordCount: Int
		let isAddRowButtonEnabled: Bool
		let isRemoveRowButtonEnabled: Bool
		let completedWords: [BIP39.Word]
		let mnemonic: Mnemonic?
		let bip39Passphrase: String
	}

	@MainActor
	public struct View: SwiftUI.View {
		@Environment(\.scenePhase) var scenePhase
		private let store: StoreOf<ImportMnemonic>

		public init(store: StoreOf<ImportMnemonic>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				ScrollView(showsIndicators: false) {
					VStack(spacing: .large1) {
						LazyVGrid(
							columns: .init(
								repeating: .init(.flexible()),
								count: 3
							)
						) {
							ForEachStore(
								store.scope(state: \.words, action: { .child(.word(id: $0, child: $1)) }),
								content: { importMnemonicWordStore in
									VStack(spacing: 0) {
										ImportMnemonicWord.View(store: importMnemonicWordStore)
										Spacer(minLength: .medium2)
									}
								}
							)
						}

						if !viewStore.isReadonlyMode {
							HStack {
								Button {
									viewStore.send(.removeRowButtonTapped)
								} label: {
									// FIXME: strings
									HStack {
										Text("Less words")
											.foregroundColor(viewStore.isRemoveRowButtonEnabled ? .app.gray1 : .app.white)
										Image(systemName: "text.badge.plus")
											.foregroundColor(viewStore.isRemoveRowButtonEnabled ? .app.red1 : .app.white)
									}
								}
								.controlState(viewStore.isRemoveRowButtonEnabled ? .enabled : .disabled)

								Spacer(minLength: 0)

								Button {
									viewStore.send(.addRowButtonTapped)
								} label: {
									// FIXME: strings
									HStack {
										Text("More words")
											.foregroundColor(viewStore.isAddRowButtonEnabled ? .app.gray1 : .app.white)
										Image(systemName: "text.badge.plus")
											.foregroundColor(viewStore.isAddRowButtonEnabled ? .app.green1 : .app.white)
									}
								}
								.controlState(viewStore.isAddRowButtonEnabled ? .enabled : .disabled)
							}
							.buttonStyle(.secondaryRectangular)
						}

						if !(viewStore.isReadonlyMode && viewStore.bip39Passphrase.isEmpty) {
							AppTextField(
								// FIXME: strings
								primaryHeading: "Passhprase",
								placeholder: "Passphrase",
								text: viewStore.binding(
									get: \.bip39Passphrase,
									send: { .passphraseChanged($0) }
								),
								// FIXME: strings
								hint: viewStore.isReadonlyMode ? nil : .info("BIP39 Passphrase is often called a '25th word'.")
							)
							.disabled(viewStore.isReadonlyMode)
							.autocorrectionDisabled()
						}
					}
					.redacted(reason: .privacy, if: viewStore.isHidingSecrets)
					.onChange(of: scenePhase) { newPhase in
						viewStore.send(.scenePhase(newPhase))
					}
					.footer {
						WithControlRequirements(
							viewStore.mnemonic,
							forAction: { viewStore.send(.continueButtonTapped($0)) }
						) { action in
							if !viewStore.isReadonlyMode {
								if viewStore.mnemonic == nil, viewStore.completedWords.count == viewStore.wordCount {
									// FIXME: strings
									Text("Mnemonic not checksummed")
										.foregroundColor(.app.red1)
								}
								// FIXME: strings
								Button("Import mnemonic", action: action)
									.buttonStyle(.primaryRectangular)
							} else {
								// FIXME: strings
								Button("Done") {
									viewStore.send(.doneViewing)
								}
								.buttonStyle(.primaryRectangular)
							}
						}
					}
				}
				.animation(.default, value: viewStore.wordCount)
				.padding(.medium3)
				.onAppear { viewStore.send(.appeared) }
				#if os(iOS)
					.screenshotProtected(isProtected: true)
				#endif // iOS
			}
		}
	}
}

extension View {
	/// Conditionally adds a reason to apply a redaction to this view hierarchy.
	///
	/// Adding a redaction is an additive process: any redaction
	/// provided will be added to the reasons provided by the parent.
	@ViewBuilder
	public func redacted(reason: RedactionReasons, if condition: @autoclosure () -> Bool) -> some View {
		if condition() {
			redacted(reason: reason)
		} else {
			self
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - ImportMnemonic_Preview
struct ImportMnemonic_Preview: PreviewProvider {
	static var previews: some View {
		ImportMnemonic.View(
			store: .init(
				initialState: .previewValue,
				reducer: ImportMnemonic()
			)
		)
	}
}

extension ImportMnemonic.State {
	public static let previewValue = Self(saveInProfile: false)
}
#endif
