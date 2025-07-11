import SwiftUI

// MARK: - ImportMnemonicForFactorSource.View
extension ImportMnemonicForFactorSource {
	struct View: SwiftUI.View {
		let store: StoreOf<ImportMnemonicForFactorSource>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack {
						factorSourceCard
						grid
							.padding(.bottom, .medium3)

						skipButton
						confirButton
					}
					.padding(.medium3)
				}
				.background(.secondaryBackground)
				.task { @MainActor in
					await store.send(.view(.task)).finish()
				}
			}
		}

		private var factorSourceCard: some SwiftUI.View {
			loadable(store.entitiesLinkedToFactorSource, successContent: { entitiesLinkedToFactorSource in
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

		private var confirButton: some SwiftUI.View {
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
	}
}

private extension StoreOf<ImportMnemonicForFactorSource> {
	var grid: StoreOf<ImportMnemonicGrid> {
		scope(state: \.grid, action: \.child.grid)
	}
}
