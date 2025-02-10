import ComposableArchitecture
import ScreenshotPreventing
import SwiftUI

extension ImportMnemonic.State {
	var viewState: ImportMnemonic.ViewState {
		.init(
			readonlyMode: mode.readonly?.context,
			hideAdvancedMode: hideAdvancedMode,
			showCloseButton: showCloseButton,
			isProgressing: mode.write?.isProgressing ?? false,
			isAdvancedMode: isAdvancedMode,
			isComplete: isComplete,
			header: header,
			warning: warning,
			completedWords: completedWords,
			mnemonic: mnemonic,
			bip39Passphrase: bip39Passphrase
		)
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
}

// MARK: - ImportMnemonic.ViewState
extension ImportMnemonic {
	struct ViewState: Equatable {
		var isReadonlyMode: Bool {
			readonlyMode != nil
		}

		let readonlyMode: ImportMnemonic.State.ReadonlyMode.Context?
		let hideAdvancedMode: Bool
		let showCloseButton: Bool
		let isProgressing: Bool // irrelevant for read only mode
		let isAdvancedMode: Bool
		let isComplete: Bool
		let header: State.Header?
		let warning: String?
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
	}
}

extension ImportMnemonic.ViewState {
	var isNonChecksummed: Bool {
		mnemonic == nil && isComplete
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
	struct View: SwiftUI.View {
		private let store: StoreOf<ImportMnemonic>

		init(store: StoreOf<ImportMnemonic>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				ScrollView(showsIndicators: false) {
					VStack(spacing: .medium3) {
						if let header = viewStore.header {
							HeaderView(header: header)
						}

						if let warning = viewStore.warning {
							StatusMessageView(text: warning, type: .warning)
						}

						ImportMnemonicGrid.View(store: store.grid)
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
				.animation(.default, value: viewStore.isAdvancedMode)
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

	var grid: StoreOf<ImportMnemonicGrid> {
		scope(state: \.grid, action: \.child.grid)
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
					StatusMessageView(text: L10n.ImportMnemonic.checksumFailure, type: .error)
				}
				Button(L10n.ImportMnemonic.importSeedPhrase, action: action)
					.buttonStyle(.primaryRectangular)
			}
			.controlState(viewStore.isProgressing ? .loading(.local) : .enabled)
		}
	}
}
