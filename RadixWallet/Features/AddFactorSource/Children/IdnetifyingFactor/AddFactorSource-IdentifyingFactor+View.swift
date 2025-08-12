import SwiftUI

// MARK: - AddFactorSource.IdentifyingFactor.View
extension AddFactorSource.IdentifyingFactor {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<AddFactorSource.IdentifyingFactor>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				VStack(spacing: .medium1) {
					Image(.addShieldBuilderSeedingFactorsAdd)
					Text("Identifying Factor")
						.textStyle(.sheetTitle)
						.foregroundStyle(.primaryText)

					Text(store.kind.identifyingDescription)
						.textStyle(.body1Regular)
						.multilineTextAlignment(.center)
						.foregroundStyle(.primaryText)
						.lineSpacing(.zero)

					Button("Retry") {
						store.send(.view(.retryButtonTapped))
					}
					.buttonStyle(.blueText)

					Spacer()
				}
				.padding(.medium3)
				.task { @MainActor in
					await store.send(.view(.task)).finish()
				}
				.withNavigationBar {
					store.send(.view(.closeButtonTapped))
				}
				.presentationDetents([.fraction(0.66)])
				.presentationDragIndicator(.hidden)
				.presentationBackground(.blur)
			}
		}
	}
}

private extension FactorSourceKind {
	var identifyingDescription: String {
		switch self {
		case .ledgerHqHardwareWallet:
			"Choose the Ledger Nano to use. Make sure it’s connected to a computer with a linked Radix Connector browser extension."
		case .arculusCard:
			"Tap and hold the Arculus Card you want to use to your phone."
		default:
			"Unknown"
		}
	}
}
