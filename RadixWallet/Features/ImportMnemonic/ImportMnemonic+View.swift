import ComposableArchitecture
import ScreenshotPreventing
import SwiftUI

extension ImportMnemonic.State {
	var viewState: ImportMnemonic.ViewState {
		var viewState = ImportMnemonic.ViewState(
			readonlyMode: mode.readonly?.context,
			hideAdvancedMode: hideAdvancedMode,
			showCloseButton: showCloseButton,
			isProgressing: mode.write?.isProgressing ?? false,
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

	private var showCloseButton: Bool {
		switch mode {
		case let .readonly(readOnlyMode):
			readOnlyMode.context == .fromBackupPrompt
		case let .write(writeMode):
			writeMode.showCloseButton
		}
	}

	private var hideAdvancedMode: Bool {
		switch mode {
		case .readonly:
			true
		case .write:
			isWordCountFixed
		}
	}

	var rowCount: Int {
		words.count / ImportMnemonic.wordsPerRow
	}
}

// MARK: - ImportMnemonic.ViewState
extension ImportMnemonic {
	public struct ViewState: Equatable {
		var isReadonlyMode: Bool {
			readonlyMode != nil
		}

		let readonlyMode: ImportMnemonic.State.ReadonlyMode.Context?
		let hideAdvancedMode: Bool
		let showCloseButton: Bool
		let isProgressing: Bool // irrelevant for read only mode
		let isWordCountFixed: Bool
		let isAdvancedMode: Bool
		let header: State.Header?
		let warning: String?
		let rowCount: Int
		let wordCount: BIP39WordCount
		let completedWords: [BIP39Word]
		let mnemonic: Mnemonic?
		let bip39Passphrase: String

		var showModeButton: Bool {
			!isReadonlyMode && !hideAdvancedMode
		}

		var showBackButton: Bool {
			guard let readonlyMode, case .fromSettings = readonlyMode else { return false }
			return true
		}

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
		if isReadonlyMode, !bip39Passphrase.isEmpty {
			return true
		}
		return isAdvancedMode && !(isReadonlyMode && bip39Passphrase.isEmpty)
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
					VStack(spacing: .medium3) {
						if let header = viewStore.header {
							HeaderView(header: header)
						}

						if let warning = viewStore.warning {
							WarningErrorView(text: warning, type: .warning)
						}

						if !viewStore.isWordCountFixed {
							VStack(alignment: .center) {
								let label = L10n.ImportMnemonic.numberOfWordsPicker
								Text(label)
									.textStyle(.body1HighImportance)
									.foregroundStyle(.app.gray1)

								Picker(label, selection: viewStore.binding(
									get: \.wordCount,
									send: { .changedWordCountTo($0) }
								)) {
									ForEach(BIP39WordCount.allCases, id: \.self) { wordCount in
										Text("\(wordCount.rawValue)")
											.textStyle(.body1Regular)
									}
								}
								.pickerStyle(.segmented)
							}
						}

						#if DEBUG
						debugSection(with: viewStore)
						#endif

						wordsGrid(with: viewStore)
							.padding(.vertical, .small1)

						if viewStore.isShowingPassphrase {
							passphrase(with: viewStore)
						}

						if viewStore.showModeButton {
							Button(viewStore.modeButtonTitle) {
								viewStore.send(.toggleModeButtonTapped)
							}
							.buttonStyle(.blueText)
							.frame(height: .large1)
							.padding(.bottom, .small2)
						}

						footer(with: viewStore)
					}
					.padding(.medium3)
				}
				.navigationBarBackButtonHidden(viewStore.showBackButton || viewStore.showCloseButton) // need to be able to hook "back" button press
				.toolbar {
					if viewStore.showBackButton {
						ToolbarItem(placement: .navigationBarLeading) {
							BackButton {
								viewStore.send(.backButtonTapped)
							}
						}
					}
					if viewStore.showCloseButton {
						ToolbarItem(placement: .navigationBarLeading) {
							CloseButton {
								viewStore.send(.closeButtonTapped)
							}
						}
					}
				}
				.animation(.default, value: viewStore.wordCount)
				.animation(.default, value: viewStore.isAdvancedMode)
				.onAppear { viewStore.send(.appeared) }
				#if !DEBUG
					.screenshotProtected(isProtected: true)
				#endif // !DEBUG
					.destinations(with: store)
			}
		}

		struct HeaderView: SwiftUI.View {
			let header: State.Header

			var body: some SwiftUI.View {
				VStack(spacing: .large2) {
					Text(header.title)
						.textStyle(.sheetTitle)

					if let subtitle = header.subtitle {
						Text(subtitle)
							.textStyle(.body1Regular)
					}
				}
				.foregroundColor(.app.gray1)
				.multilineTextAlignment(.center)
				.padding(.horizontal, .small1)
			}
		}
	}
}

private extension StoreOf<ImportMnemonic> {
	var destination: PresentationStoreOf<ImportMnemonic.Destination> {
		func scopeState(state: State) -> PresentationState<ImportMnemonic.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<ImportMnemonic>) -> some View {
		let destinationStore = store.destination
		return onContinueWarning(with: destinationStore)
			.backupConfirmation(with: destinationStore)
			.verifyMnemonic(with: destinationStore)
	}

	private func backupConfirmation(with destinationStore: PresentationStoreOf<ImportMnemonic.Destination>) -> some View {
		alert(store: destinationStore.scope(state: \.backupConfirmation, action: \.backupConfirmation))
	}

	private func onContinueWarning(with destinationStore: PresentationStoreOf<ImportMnemonic.Destination>) -> some View {
		alert(store: destinationStore.scope(state: \.onContinueWarning, action: \.onContinueWarning))
	}

	private func verifyMnemonic(with destinationStore: PresentationStoreOf<ImportMnemonic.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.verifyMnemonic, action: \.verifyMnemonic)) {
			VerifyMnemonic.View(store: $0)
		}
	}
}

extension ImportMnemonic.View {
	@ViewBuilder
	private func wordsGrid(with viewStore: ViewStoreOf<ImportMnemonic>) -> some View {
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
	private func footer(with viewStore: ViewStoreOf<ImportMnemonic>) -> some View {
		if viewStore.isReadonlyMode {
			Button(L10n.Common.done) {
				viewStore.send(.doneViewing)
			}
			.buttonStyle(.primaryRectangular)
		} else {
			WithControlRequirements(
				viewStore.mnemonic,
				forAction: { viewStore.send(.continueButtonTapped($0)) }
			) { action in
				if viewStore.isNonChecksummed {
					WarningErrorView(text: L10n.ImportMnemonic.checksumFailure, type: .error)
				} else {
					// We need to leave some empty space before the button. Otherwise, the keyboard will get automatically dismissed
					// when focused on one of the last 3 words. It only happens on release mode, since it is related to the screenshot
					// prevention solution (which isn't enabled in debug).
					// More info: https://radixdlt.atlassian.net/browse/ABW-3789
					Spacer(minLength: .small3)
				}
				Button(L10n.ImportMnemonic.importSeedPhrase, action: action)
					.buttonStyle(.primaryRectangular)
			}
			.controlState(viewStore.isProgressing ? .loading(.local) : .enabled)
		}
	}

	#if DEBUG
	private func debugSection(with viewStore: ViewStoreOf<ImportMnemonic>) -> some View {
		VStack(spacing: .medium3) {
			if viewStore.isReadonlyMode {
				Button("DEBUG ONLY Copy") {
					viewStore.send(.debugCopyMnemonic)
				}
				.buttonStyle(.secondaryRectangular(shouldExpand: true, isDestructive: true, isInToolbar: true))
			} else {
				if !(viewStore.isWordCountFixed && viewStore.wordCount == .twentyFour) {
					Button("DEBUG AccRecScan Olympia 15") {
						viewStore.send(.debugUseOlympiaTestingMnemonicWithActiveAccounts(continue: true))
					}
					.buttonStyle(.secondaryRectangular(shouldExpand: true, isDestructive: true, isInToolbar: true))
					.overlay(alignment: .trailing) {
						Button("M") {
							viewStore.send(.debugUseOlympiaTestingMnemonicWithActiveAccounts(continue: false))
						}
						.frame(width: 40)
					}
				}

				Button("DEBUG AccRecScan Babylon 24") {
					viewStore.send(.debugUseBabylonTestingMnemonicWithActiveAccounts(continue: true))
				}
				.buttonStyle(.secondaryRectangular(shouldExpand: true, isDestructive: true, isInToolbar: true))
				.overlay(alignment: .trailing) {
					Button("M") {
						viewStore.send(.debugUseBabylonTestingMnemonicWithActiveAccounts(continue: false))
					}
					.frame(width: 40)
				}

				Button("DEBUG zoo..vote (24)") {
					viewStore.send(.debugUseTestingMnemonicZooVote(continue: true))
				}
				.buttonStyle(.secondaryRectangular(shouldExpand: true, isDestructive: true, isInToolbar: true))
				.overlay(alignment: .trailing) {
					Button("M") {
						viewStore.send(.debugUseTestingMnemonicZooVote(continue: false))
					}
					.frame(width: 40)
				}

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
			}
		}
	}
	#endif
}
