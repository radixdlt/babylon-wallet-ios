import SwiftUI

// MARK: - PrepareFactors.AddHardwareFactor.View
extension PrepareFactors.AddHardwareFactor {
	struct View: SwiftUI.View {
		let store: StoreOf<PrepareFactors.AddHardwareFactor>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack(spacing: .large2) {
						Image(.iconSecurityFactors)

						Text("Add a Hardware Device")
							.textStyle(.sheetTitle)
							.padding(.horizontal, .medium3)

						Text("Choose a hardware device to use as a security factor in your Shield.")
							.textStyle(.body1Regular)
							.padding(.horizontal, .medium2)

						VStack(spacing: .medium3) {
							card(.arculusCard)
							card(.ledgerHqHardwareWallet)
						}

						Spacer()
					}
					.foregroundStyle(.app.gray1)
					.multilineTextAlignment(.center)
					.padding(.horizontal, .medium3)
				}
				.footer {
					VStack(spacing: .small2) {
						Button("Add Hardware Device") {
							store.send(.view(.addButtonTapped))
						}
						.buttonStyle(.primaryRectangular)
						.controlState(store.controlState)

						Button("I don’t have a hardware device") {
							store.send(.view(.noDeviceButtonTapped))
						}
						.buttonStyle(.alternativeRectangular)
					}
				}
				.destinations(with: store)
			}
		}

		private func card(_ factorSource: FactorSourceKind) -> some SwiftUI.View {
			FactorSourceCard(kind: .genericDescription(factorSource), mode: .selection(type: .radioButton, isSelected: store.selected == factorSource))
				.onTapGesture {
					store.send(.view(.selected(factorSource)))
				}
		}
	}
}

private extension PrepareFactors.AddHardwareFactor.State {
	var controlState: ControlState {
		selected == nil ? .disabled : .enabled
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<PrepareFactors.AddHardwareFactor>) -> some View {
		let destinationStore = store.scope(state: \.$destination, action: \.destination)
		return addLedger(with: destinationStore)
			.noDeviceAlert(with: destinationStore)
	}

	private func addLedger(with destinationStore: PresentationStoreOf<PrepareFactors.AddHardwareFactor.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.addLedger, action: \.addLedger)) {
			AddLedgerFactorSource.View(store: $0)
		}
	}

	private func noDeviceAlert(with destinationStore: PresentationStoreOf<PrepareFactors.AddHardwareFactor.Destination>) -> some View {
		alert(store: destinationStore.scope(state: \.noDeviceAlert, action: \.noDeviceAlert))
	}
}
