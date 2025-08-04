import SwiftUI

// MARK: - ArculusForgotPIN.InputSeedPhrase.View
extension ArculusForgotPIN.InputSeedPhrase {
	struct View: SwiftUI.View {
		let store: StoreOf<ArculusForgotPIN.InputSeedPhrase>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack {
						VStack(spacing: .medium2) {
							Text("Enter Seed Phrase")
								.textStyle(.sheetTitle)

							Text("Enter your Arculus seed phrase")
								.textStyle(.body1Regular)
						}
						.foregroundColor(Color.primaryText)
						.multilineTextAlignment(.center)
						.padding(.horizontal, .small2)

						ImportMnemonicGrid.View(store: store.grid)

						if let hint = store.mnemonicHint {
							Hint(viewState: hint)
						}
					}
					.padding(.medium2)
				}
				.footer {
					WithControlRequirements(
						store.mnemonic,
						forAction: { store.send(.view(.confirmButtonTapped($0))) }
					) { action in
						Button(L10n.Common.confirm, action: action)
							.buttonStyle(.primaryRectangular)
					}
				}
				.background(Color.primaryBackground)
				.destination(store: store)
			}
		}
	}
}

private extension StoreOf<ArculusForgotPIN.InputSeedPhrase> {
	var grid: StoreOf<ImportMnemonicGrid> {
		scope(state: \.grid, action: \.child.grid)
	}

	var destination: PresentationStoreOf<ArculusForgotPIN.InputSeedPhrase.Destination> {
		scope(state: \.$destination, action: \.destination)
	}
}

@MainActor
private extension View {
	func destination(store: StoreOf<ArculusForgotPIN.InputSeedPhrase>) -> some View {
		let destinationStore = store.destination
		return enterNewPIN(with: destinationStore)
	}

	private func enterNewPIN(with destinationStore: PresentationStoreOf<ArculusForgotPIN.InputSeedPhrase.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.configureNewPIN, action: \.configureNewPIN)) {
			ArculusForgotPIN.EnterNewPIN.View(store: $0)
		}
	}
}
