import Cryptography
import FeaturePrelude
#if os(iOS)
import ScreenshotPreventing
#endif

extension ImportMnemonic.State {
	var viewState: ImportMnemonic.ViewState {
		var viewState = ImportMnemonic.ViewState(
			isReadonlyMode: isReadonlyMode,
			isWordCountFixed: isWordCountFixed,
			isAdvancedMode: isAdvancedMode,
			header: header,
			warning: warning,
			rowCount: rowCount,
			wordCount: wordCount,
			completedWords: completedWords,
			mnemonic: mnemonic,
			bip39Passphrase: bip39Passphrase
		)
		#if DEBUG
		viewState.debugMnemonicPhraseSingleField = self.debugMnemonicPhraseSingleField
		#endif
		return viewState
	}

	var rowCount: Int {
		words.count / ImportMnemonic.wordsPerRow
	}
}

// MARK: - ImportMnemonic.ViewState
extension ImportMnemonic {
	public struct ViewState: Equatable {
		let isReadonlyMode: Bool
		let isWordCountFixed: Bool
		let isAdvancedMode: Bool
		let header: State.Header?
		let warning: String?
		let rowCount: Int
		let wordCount: BIP39.WordCount
		let completedWords: [BIP39.Word]
		let mnemonic: Mnemonic?
		let bip39Passphrase: String
		#if DEBUG
		var debugMnemonicPhraseSingleField: String = ""
		#endif
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
		isAdvancedMode && !(isReadonlyMode && bip39Passphrase.isEmpty)
	}

	var modeButtonTitle: String {
		isAdvancedMode ? L10n.ImportMnemonic.regularModeButton : L10n.ImportMnemonic.advancedModeButton
	}
}

// MARK: - ImportMnemonic.View
extension ImportMnemonic {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ImportMnemonic>

		public init(store: StoreOf<ImportMnemonic>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				ScrollView(showsIndicators: false) {
					VStack(spacing: 0) {
						if let header = viewStore.header {
							HeaderView(header: header)
								.padding(.bottom, .medium1)
						}

						if let warning = viewStore.warning {
							WarningErrorView(text: warning, type: .warning)
								.padding(.top, viewStore.header == nil ? .medium3 : 0)
								.padding(.horizontal, .large3)
								.padding(.bottom, .large3)
						}

						wordsGrid(with: viewStore)
							.padding(.horizontal, .medium2)
							.padding(.bottom, .large3)

						if !viewStore.isWordCountFixed {
							changeWordCountButtons(with: viewStore)
								.padding(.horizontal, .medium2)
								.padding(.bottom, .large3)
						}

						if viewStore.isShowingPassphrase {
							passphrase(with: viewStore)
								.padding(.horizontal, .medium2)
								.padding(.bottom, .medium2)
						}

						#if DEBUG
						if viewStore.isReadonlyMode {
							Button("DEBUG ONLY Copy") {
								viewStore.send(.debugCopyMnemonic)
							}
							.buttonStyle(.secondaryRectangular(isDestructive: true))
							.padding(.bottom, .medium1)
						} else if viewStore.isAdvancedMode {
							AppTextField(
								placeholder: "DEBUG ONLY paste mnemonic",
								text: viewStore.binding(
									get: { $0.debugMnemonicPhraseSingleField },
									send: { .debugMnemonicChanged($0) }
								),
								innerAccessory: {
									Button("Paste") {
										viewStore.send(.debugPasteMnemonic)
									}
									.buttonStyle(.borderedProminent)
								}
							)
							.padding(.horizontal, .medium2)
							.padding(.bottom, .medium2)
						}
						#endif

						if !viewStore.isReadonlyMode {
							Button(viewStore.modeButtonTitle) {
								viewStore.send(.toggleModeButtonTapped)
							}
							.buttonStyle(.blue)
							.frame(height: .large1)
							.padding(.bottom, .medium1)
						}

						footer(with: viewStore)
					}
				}
				.animation(.default, value: viewStore.wordCount)
				.animation(.default, value: viewStore.isAdvancedMode)
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

		struct HeaderView: SwiftUI.View {
			let header: State.Header

			var body: some SwiftUI.View {
				VStack(spacing: 0) {
					Text(header.title)
						.textStyle(.sheetTitle)
						.padding(.bottom, .large2)

					if let subtitle = header.subtitle {
						Text(subtitle)
							.textStyle(.body1Regular)
					}
				}
				.foregroundColor(.app.gray1)
				.multilineTextAlignment(.center)
				.padding(.horizontal, .large3)
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
			ForEachStore(store.scope(state: \.words, action: { .child(.word(id: $0, child: $1)) })) {
				ImportMnemonicWord.View(store: $0)
			}
		}
	}

	@ViewBuilder
	private func passphrase(with viewStore: ViewStoreOf<ImportMnemonic>) -> some SwiftUI.View {
		AppTextField(
			primaryHeading: .init(text: L10n.ImportMnemonic.passphrase, isProminent: true),
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
					WarningErrorView(text: L10n.ImportMnemonic.checksumFailure, type: .error)
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
		.padding([.horizontal, .bottom], .medium2)
	}
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - ImportMnemonic_Preview
// struct ImportMnemonic_Preview: PreviewProvider {
//	static var previews: some View {
//		ImportMnemonic.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: ImportMnemonic()
//			)
//		)
//	}
// }
//
// extension ImportMnemonic.State {
//	public static let previewValue = Self(persistStrategy: .intoKeychainOnly, mnemonicForFactorSourceKind: .offDevice)
// }
// #endif
