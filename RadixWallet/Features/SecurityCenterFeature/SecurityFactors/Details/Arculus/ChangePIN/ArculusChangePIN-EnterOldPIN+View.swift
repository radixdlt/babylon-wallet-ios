import SwiftUI

// MARK: - ArculusChangePIN.EnterOldPIN.View
extension ArculusChangePIN.EnterOldPIN {
	struct View: SwiftUI.View {
		let store: StoreOf<ArculusChangePIN.EnterOldPIN>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack(spacing: .small2) {
						Text("Enter your current Arculus PIN")
							.textStyle(.body1Regular)
							.foregroundStyle(.primaryText)
							.multilineTextAlignment(.center)

						ArculusPINInput.View(store: store.scope(state: \.pinInput, action: \.child.pinInput))

						Spacer()
					}
					.padding(.medium3)
				}
				.footer {
					WithControlRequirements(store.pinInput.validatedPin, forAction: { store.send(.view(.pinAdded($0))) }) { action in
						Button(L10n.Common.continue) {
							action()
						}
						.buttonStyle(.primaryRectangular)
					}
				}
				.destination(store: store)
				.navigationTitle("Change PIN")
			}
		}
	}
}

private extension StoreOf<ArculusChangePIN.EnterOldPIN> {
	var destination: PresentationStoreOf<ArculusChangePIN.EnterOldPIN.Destination> {
		scope(state: \.$destination, action: \.destination)
	}
}

@MainActor
private extension View {
	func destination(store: StoreOf<ArculusChangePIN.EnterOldPIN>) -> some View {
		let destinationStore = store.destination
		return enterNewPIN(with: destinationStore)
	}

	private func enterNewPIN(with destinationStore: PresentationStoreOf<ArculusChangePIN.EnterOldPIN.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.configureNewPIN, action: \.configureNewPIN)) {
			ArculusChangePIN.EnterNewPIN.View(store: $0)
		}
	}
}
