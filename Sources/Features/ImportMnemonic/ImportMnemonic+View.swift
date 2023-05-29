import Cryptography
import FeaturePrelude
#if os(iOS)
import ScreenshotPreventing
#endif

extension ImportMnemonic.State {
	var viewState: ImportMnemonic.ViewState {
		.init(
			isReadonlyMode: isReadonlyMode,
			isHidingSecrets: isHidingSecrets,
			rowCount: rowCount,
			wordCount: wordCount,
			completedWords: completedWords,
			mnemonic: mnemonic,
			bip39Passphrase: bip39Passphrase
		)
	}

	var rowCount: Int {
		words.count / ImportMnemonic.wordsPerRow
	}
}

// MARK: - ImportMnemonic.ViewState
extension ImportMnemonic {
	public struct ViewState: Equatable {
		let isReadonlyMode: Bool
		let isHidingSecrets: Bool
		let rowCount: Int
		let wordCount: BIP39.WordCount
		let completedWords: [BIP39.Word]
		let mnemonic: Mnemonic?
		let bip39Passphrase: String
	}
}

extension ImportMnemonic.ViewState {
	var isNonChecksummed: Bool {
		mnemonic == nil && completedWords.count == wordCount.rawValue
	}

	var isAddRowButtonEnabled: Bool {
		wordCount != .twentyFour
	}

	var isRemoveRowButtonEnabled: Bool {
		wordCount != .twelve
	}

	var isShowingPassphrase: Bool {
		!(isReadonlyMode && bip39Passphrase.isEmpty)
	}

	var isShowingChangeWordCountButtons: Bool {
		!isReadonlyMode
	}
}

// MARK: - ImportMnemonic.View
extension ImportMnemonic {
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
						wordsGrid(with: viewStore)

						if viewStore.isShowingChangeWordCountButtons {
							changeWordCountButtons(with: viewStore)
						}

						if viewStore.isShowingPassphrase {
							passphrase(with: viewStore)
						}
					}
					.padding(.horizontal, .small3)
					.redacted(reason: .privacy, if: viewStore.isHidingSecrets)
					.onChange(of: scenePhase) { newPhase in
						viewStore.send(.scenePhase(newPhase))
					}
					.footer {
						footer(with: viewStore)
					}
				}
				.animation(.default, value: viewStore.wordCount)
				.padding(.medium3)
				.onAppear { viewStore.send(.appeared) }
				#if !DEBUG && os(iOS)
					.screenshotProtected(isProtected: true)
				#endif // iOS
					.sheet(
						store: store.scope(
							state: \.$offDeviceMnemonicInfoPrompt,
							action: { .child(.offDeviceMnemonicInfoPrompt($0)) }
						),
						content: {
							OffDeviceMnemonicInfo.View(store: $0)
						}
					)
			}
		}
	}
}

extension ImportMnemonic.View {
	@ViewBuilder
	private func wordsGrid(with viewStore: ViewStoreOf<ImportMnemonic>) -> some SwiftUI.View {
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
	}

	@ViewBuilder
	private func passphrase(with viewStore: ViewStoreOf<ImportMnemonic>) -> some SwiftUI.View {
		AppTextField(
			primaryHeading: .init(text: L10n.ImportMnemonic.passphrase, isProminent: false),
			placeholder: L10n.ImportMnemonic.passphrasePlaceholder,
			text: viewStore.binding(
				get: \.bip39Passphrase,
				send: { .passphraseChanged($0) }
			),
			hint: viewStore.isReadonlyMode ? nil : .info(L10n.ImportMnemonic.passphraseHint)
		)
		.disabled(viewStore.isReadonlyMode)
		.autocorrectionDisabled()
	}

	@ViewBuilder
	private func changeWordCountButtons(with viewStore: ViewStoreOf<ImportMnemonic>) -> some SwiftUI.View {
		HStack {
			Button {
				viewStore.send(.removeRowButtonTapped)
			} label: {
				HStack {
					Text(L10n.ImportMnemonic.fewerWords)
						.foregroundColor(viewStore.isRemoveRowButtonEnabled ? .app.gray1 : .app.white)
					Image(systemName: "text.badge.minus")
						.foregroundColor(viewStore.isRemoveRowButtonEnabled ? .app.red1 : .app.white)
				}
			}
			.controlState(viewStore.isRemoveRowButtonEnabled ? .enabled : .disabled)

			Spacer(minLength: 0)

			Button {
				viewStore.send(.addRowButtonTapped)
			} label: {
				HStack {
					Text(L10n.ImportMnemonic.moreWords)
						.foregroundColor(viewStore.isAddRowButtonEnabled ? .app.gray1 : .app.white)
					Image(systemName: "text.badge.plus")
						.foregroundColor(viewStore.isAddRowButtonEnabled ? .app.green1 : .app.white)
				}
			}
			.controlState(viewStore.isAddRowButtonEnabled ? .enabled : .disabled)
		}
		.buttonStyle(.secondaryRectangular)
	}

	@ViewBuilder
	private func footer(with viewStore: ViewStoreOf<ImportMnemonic>) -> some SwiftUI.View {
		WithControlRequirements(
			viewStore.mnemonic,
			forAction: { viewStore.send(.continueButtonTapped($0)) }
		) { action in
			if !viewStore.isReadonlyMode {
				if viewStore.isNonChecksummed {
					Text(L10n.ImportMnemonic.checksumFailure)
						.foregroundColor(.app.red1)
				}
				Button(L10n.ImportMnemonic.importSeedPhrase, action: action)
					.buttonStyle(.primaryRectangular)
			} else {
				Button(L10n.Common.done) {
					viewStore.send(.doneViewing)
				}
				.buttonStyle(.primaryRectangular)
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
	public static let previewValue = Self(persistAsMnemonicKind: nil)
}
#endif
