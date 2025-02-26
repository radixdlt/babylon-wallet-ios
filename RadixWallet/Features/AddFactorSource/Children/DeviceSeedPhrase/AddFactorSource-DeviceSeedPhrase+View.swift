import SwiftUI

// MARK: - AddFactorSource.DeviceSeedPhrase.View
extension AddFactorSource.DeviceSeedPhrase {
	struct View: SwiftUI.View {
		let store: StoreOf<AddFactorSource.DeviceSeedPhrase>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					coreView
						.padding(.horizontal, .medium2)
				}
				.footer {
					Button(L10n.Common.confirm) {
						store.send(.view(.confirmButtonTapped))
					}
					.buttonStyle(.primaryRectangular)
					.controlState(store.confirmButtonControlState)
				}
				.onFirstAppear {
					store.send(.view(.onFirstAppear))
				}
			}
			.destination(store: store)
		}

		@MainActor
		private var coreView: some SwiftUI.View {
			VStack(spacing: .huge2) {
				headerView

				ImportMnemonicGrid.View(store: store.grid)
			}
		}

		private var headerView: some SwiftUI.View {
			VStack(spacing: .medium2) {
				Text("Write Down Seed Phrase")
					.textStyle(.sheetTitle)

				Text("Write down this BIP39 seed phrase and store safely for future use. Avoid storing electronically so no one can steal it online.")
					.textStyle(.body1Regular)
			}
			.foregroundColor(.app.gray1)
			.multilineTextAlignment(.center)
			.padding(.horizontal, .small2)
		}
	}
}

private extension StoreOf<AddFactorSource.DeviceSeedPhrase> {
	var grid: StoreOf<ImportMnemonicGrid> {
		scope(state: \.grid, action: \.child.grid)
	}

	var destination: PresentationStoreOf<AddFactorSource.DeviceSeedPhrase.Destination> {
		func scopeState(state: State) -> PresentationState<AddFactorSource.DeviceSeedPhrase.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destination(store: StoreOf<AddFactorSource.DeviceSeedPhrase>) -> some View {
		let destinationStore = store.destination
		return factorAlreadyInUseAlert(with: destinationStore)
	}

	private func factorAlreadyInUseAlert(with destinationStore: PresentationStoreOf<AddFactorSource.DeviceSeedPhrase.Destination>) -> some View {
		alert(store: destinationStore.scope(state: \.factorAlreadyInUseAlert, action: \.factorAlreadyInUseAlert))
	}
}
