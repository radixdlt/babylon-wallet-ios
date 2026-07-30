import SwiftUI

// MARK: - FactorSourceAccess.View
extension FactorSourceAccess {
	struct View: SwiftUI.View {
		let store: StoreOf<FactorSourceAccess>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				content
					.background(.secondaryBackground)
					.scrollableWithBottomSpacer()
					.withNavigationBar {
						store.send(.view(.closeButtonTapped))
					}
					.presentationDetents([.fraction(0.75), .large])
					.presentationDragIndicator(.visible)
					.interactiveDismissDisabled()
					.presentationBackground(.blur)
					.onFirstTask { @MainActor in
						await store.send(.view(.onFirstTask)).finish()
					}
					.destinations(with: store)
			}
		}

		private var content: some SwiftUI.View {
			VStack(spacing: .small3) {
				Image(.signingKey)
					.foregroundColor(.iconTertiary)

				VStack(spacing: .small2) {
					Text(store.title)
						.textStyle(.sheetTitle)

					Text(LocalizedStringKey(store.message))
						.textStyle(.body1Regular)
				}
				.foregroundColor(.primaryText)

				card
				retry
				input
				skip
			}
			.multilineTextAlignment(.center)
			.padding(.horizontal, .large2)
		}

		@ViewBuilder
		private var card: some SwiftUI.View {
			if let factorSource = store.factorSource {
				FactorSourceCard(
					kind: .instance(
						factorSource: factorSource,
						kind: .short(showDetails: false)
					),
					mode: .display
				)
			} else {
				ProgressView()
			}
		}

		@ViewBuilder
		private var retry: some SwiftUI.View {
			if store.isRetryEnabled {
				Button(L10n.Common.retry) {
					store.send(.view(.retryButtonTapped))
				}
				.buttonStyle(.primaryText(height: .standardButtonHeight))
			}
		}

		@ViewBuilder
		private var input: some SwiftUI.View {
			if let child = store.password {
				PasswordFactorSourceAccess.View(store: child)
			} else if let child = store.deviceMnemonic {
				DeviceMnemonicFactorSourceAccess.View(store: child)
			} else if let child = store.offDeviceMnemonic {
				OffDeviceMnemonicFactorSourceAccess.View(store: child)
			} else if let child = store.arculus {
				ArculusFactorSourceAccess.View(store: child)
			}
		}

		@ViewBuilder
		private var skip: some SwiftUI.View {
			if let text = store.skipButtonText {
				Button(text) {
					store.send(.view(.skipButtonTapped))
				}
				.buttonStyle(.primaryText(height: .standardButtonHeight))
			}
		}
	}
}

private extension StoreOf<FactorSourceAccess> {
	var destination: PresentationStoreOf<FactorSourceAccess.Destination> {
		func scopeState(state: State) -> PresentationState<FactorSourceAccess.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}

	var password: Store<PasswordFactorSourceAccess.State, PasswordFactorSourceAccess.Action>? {
		scope(state: \.password, action: \.child.password)
	}

	var deviceMnemonic: Store<DeviceMnemonicFactorSourceAccess.State, DeviceMnemonicFactorSourceAccess.Action>? {
		scope(state: \.deviceMnemonic, action: \.child.deviceMnemonic)
	}

	var offDeviceMnemonic: Store<OffDeviceMnemonicFactorSourceAccess.State, OffDeviceMnemonicFactorSourceAccess.Action>? {
		scope(state: \.offDeviceMnemonic, action: \.child.offDeviceMnemonic)
	}

	var arculus: Store<ArculusFactorSourceAccess.State, ArculusFactorSourceAccess.Action>? {
		scope(state: \.arculus, action: \.child.arculus)
	}
}

// MARK: - DeviceMnemonicFactorSourceAccess.View
extension DeviceMnemonicFactorSourceAccess {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<DeviceMnemonicFactorSourceAccess>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				VStack(alignment: .leading, spacing: .medium3) {
					Text(L10n.FactorSourceActions.Device.mnemonicUnavailableMessage)
						.textStyle(.body1Regular)
						.foregroundColor(.primaryText)
						.multilineTextAlignment(.center)

					ImportMnemonicGrid.View(store: store.grid)
						.padding(.horizontal, -.small1)

					if store.isAdvancedMode {
						AppTextField(
							primaryHeading: .init(text: L10n.ImportMnemonic.passphrase, isProminent: true),
							placeholder: L10n.ImportMnemonic.passphrasePlaceholder,
							text: $store.bip39Passphrase.sending(\.view.passphraseChanged),
							hint: .info(L10n.ImportMnemonic.passphraseHint),
							preventScreenshot: true
						)
						.autocorrectionDisabled()
					}

					Button(store.isAdvancedMode ? L10n.ImportMnemonic.regularModeButton : L10n.ImportMnemonic.advancedModeButton) {
						store.send(.view(.toggleModeButtonTapped))
					}
					.buttonStyle(.blueText)

					if let hint = store.hint {
						Hint(viewState: hint)
					}

					Button(L10n.Common.confirm) {
						store.send(.view(.confirmButtonTapped))
					}
					.buttonStyle(.primaryRectangular)
					.controlState(store.confirmButtonControlState)
				}
			}
		}
	}
}

private extension StoreOf<DeviceMnemonicFactorSourceAccess> {
	var grid: StoreOf<ImportMnemonicGrid> {
		scope(state: \.grid, action: \.child.grid)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<FactorSourceAccess>) -> some View {
		let destinationStore = store.destination
		return errorAlert(with: destinationStore)
	}

	private func errorAlert(with destinationStore: PresentationStoreOf<FactorSourceAccess.Destination>) -> some View {
		alert(store: destinationStore.scope(state: \.errorAlert, action: \.errorAlert))
	}
}
