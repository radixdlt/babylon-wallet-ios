import SwiftUI

// MARK: - ImportMnemonicForFactorSource.View
extension ImportMnemonicForFactorSource {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<ImportMnemonicForFactorSource>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack {
						factorSourceCard
						grid
							.padding(.bottom, .medium3)

						if store.advancedModeEnabled {
							passphrase
						}

						if store.hasPassphrase {
							modeToggleButton
						}

						if store.isAllowedToSkip {
							skipButton
						}
						confirmButton
					}
					.padding(.medium3)
				}
				.radixToolbar(
					title: "Enter Seed Phrase",
					closeAction: {
						store.send(.view(.closeButtonTapped))
					}
				)
				.background(.secondaryBackground)
				.task { @MainActor in
					await store.send(.view(.task)).finish()
				}
			}
		}

		private var factorSourceCard: some SwiftUI.View {
			loadable(store.entitiesLinkedToFactorSource, successContent: { entitiesLinkedToFactorSource in
				WithPerceptionTracking {
					FactorSourceCard(
						kind: .instance(
							factorSource: entitiesLinkedToFactorSource.integrity.factorSource,
							kind: .withEntities(linkedEntities: .init(
								accounts: entitiesLinkedToFactorSource.accounts,
								personas: entitiesLinkedToFactorSource.personas,
								hasHiddenEntities: false
							))
						),
						mode: .display,
						isExpanded: false
					)
				}
			})
		}

		private var grid: some SwiftUI.View {
			VStack(alignment: .leading, spacing: .zero) {
				ImportMnemonicGrid.View(store: store.grid)

				if let hint = store.hint {
					Hint(viewState: hint)
				}
			}
		}

		private var confirmButton: some SwiftUI.View {
			Button(L10n.Common.confirm) {
				store.send(.view(.confirmButtonTapped))
			}
			.buttonStyle(.primaryRectangular)
			.controlState(store.confirmButtonControlState)
		}

		private var skipButton: some SwiftUI.View {
			Button(L10n.RecoverSeedPhrase.skipButton) {
				store.send(.view(.skipButtonTapped))
			}
			.buttonStyle(.blueText)
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

private extension StoreOf<ImportMnemonicForFactorSource> {
	var grid: StoreOf<ImportMnemonicGrid> {
		scope(state: \.grid, action: \.child.grid)
	}
}
