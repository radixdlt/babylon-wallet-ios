import SwiftUI

// MARK: - AddFactorSource.InputSeedPhrase.View
extension AddFactorSource.InputSeedPhrase {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<AddFactorSource.InputSeedPhrase>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollViewReader { proxy in
					WithPerceptionTracking {
						ScrollView {
							Color.clear.frame(height: 0).id("top_anchor")

							coreView(scrollViewProxy: proxy)
								.padding(.medium2)
						}
						.footer {
							Button(L10n.Common.confirm) {
								store.send(.view(.confirmButtonTapped))
							}
							.buttonStyle(.primaryRectangular)
							.controlState(store.confirmButtonControlState)
						}
						.background(Color.primaryBackground)
					}
				}
			}
			.destination(store: store)
		}

		@MainActor
		private func coreView(scrollViewProxy: ScrollViewProxy) -> some SwiftUI.View {
			VStack(spacing: .medium3) {
				headerView

				ImportMnemonicGrid.View(store: store.grid)
				if store.advancedModeEnabled {
					passphrase
				}

				if store.hasPassphrase {
					modeToggleButton
				}

				if !store.isEnteringCustomSeedPhrase {
					Button(L10n.NewBiometricFactor.SeedPhrase.enterCustomButton) {
						store.send(.view(.enterCustomSeedPhraseButtonTapped))
						withAnimation {
							scrollViewProxy.scrollTo("top_anchor", anchor: .top)
						}
					}
					.buttonStyle(.blueText)
				}
			}
		}

		private var headerView: some SwiftUI.View {
			VStack(spacing: .medium2) {
				Text(headerTitle)
					.textStyle(.sheetTitle)

				Text(headerMessage)
					.textStyle(.body1Regular)
			}
			.foregroundColor(Color.primaryText)
			.multilineTextAlignment(.center)
			.padding(.horizontal, .small2)
		}

		var headerTitle: String {
			if store.isEnteringCustomSeedPhrase {
				"Enter your BIP39 seed phrase"
			} else {
				L10n.NewBiometricFactor.SeedPhrase.title
			}
		}

		var headerMessage: String {
			if store.isEnteringCustomSeedPhrase {
				"Enter your BIP39 seed phrase. Make sure it’s backed up securely and accessible only to you."
			} else {
				L10n.NewBiometricFactor.SeedPhrase.subtitle
			}
		}

		private var passphrase: some SwiftUI.View {
			AppTextField(
				primaryHeading: .init(text: L10n.ImportMnemonic.passphrase, isProminent: true),
				placeholder: L10n.ImportMnemonic.passphrasePlaceholder,
				text: $store.bip39Passphrase.sending(\.view.passphraseChanged),
				hint: .info(L10n.ImportMnemonic.passphraseHint)
			)
			.autocorrectionDisabled()
		}

		private var modeToggleButton: some SwiftUI.View {
			Button(store.advancedModeEnabled ? L10n.ImportMnemonic.regularModeButton : L10n.ImportMnemonic.advancedModeButton) {
				store.send(.view(.toggleModeButtonTapped))
			}
			.buttonStyle(.blueText)
			.frame(height: .large1)
			.padding(.bottom, .small2)
		}
	}
}

private extension StoreOf<AddFactorSource.InputSeedPhrase> {
	var grid: StoreOf<ImportMnemonicGrid> {
		scope(state: \.grid, action: \.child.grid)
	}

	var destination: PresentationStoreOf<AddFactorSource.InputSeedPhrase.Destination> {
		scope(state: \.$destination, action: \.destination)
	}
}

@MainActor
private extension View {
	func destination(store: StoreOf<AddFactorSource.InputSeedPhrase>) -> some View {
		let destinationStore = store.destination
		return factorAlreadyInUseAlert(with: destinationStore)
	}

	private func factorAlreadyInUseAlert(with destinationStore: PresentationStoreOf<AddFactorSource.InputSeedPhrase.Destination>) -> some View {
		alert(store: destinationStore.scope(state: \.factorAlreadyInUseAlert, action: \.factorAlreadyInUseAlert))
	}
}
