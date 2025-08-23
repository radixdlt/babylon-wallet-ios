import SwiftUI

// MARK: - ArculusFactorSourceAccess.View
extension ArculusFactorSourceAccess {
	struct View: SwiftUI.View {
		let store: StoreOf<ArculusFactorSourceAccess>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				VStack(spacing: .medium3) {
					ArculusPINInput.View(store: store.scope(state: \.pinInput, action: \.child.pinInput))
					Button("Forgot PIN") {
						store.send(.view(.forgotPinButtonTapped))
					}
					.buttonStyle(.blueText)
					.flushedLeft
					WithControlRequirements(store.pinInput.validatedPin, forAction: { store.send(.view(.pinAdded($0))) }) { action in
						Button(L10n.Common.confirm, action: action)
							.buttonStyle(.primaryRectangular)
					}
				}
				.destination(store: store)
			}
		}
	}
}

private extension StoreOf<ArculusFactorSourceAccess> {
	var destination: PresentationStoreOf<ArculusFactorSourceAccess.Destination> {
		scope(state: \.$destination, action: \.destination)
	}
}

@MainActor
private extension View {
	func destination(store: StoreOf<ArculusFactorSourceAccess>) -> some View {
		let destinationStore = store.destination
		return arculusForgotPIN(with: destinationStore)
	}

	private func arculusForgotPIN(with destinationStore: PresentationStoreOf<ArculusFactorSourceAccess.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.arculusForgotPIN, action: \.arculusForgotPIN)) { store in
			NavigationStack {
				ArculusForgotPIN.InputSeedPhrase.View(store: store)
			}
		}
	}
}
