import SwiftUI

// MARK: - ArculusChangePIN-EnterNewPIN.View
extension ArculusChangePIN.EnterNewPIN {
	struct View: SwiftUI.View {
		let store: StoreOf<ArculusChangePIN.EnterNewPIN>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack(spacing: .small2) {
						Text("Enter your new Arculus PIN")
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
				.navigationTitle("Change PIN")
			}
		}
	}
}
