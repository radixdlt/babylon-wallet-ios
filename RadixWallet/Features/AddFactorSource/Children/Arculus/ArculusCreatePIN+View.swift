import SwiftUI

// MARK: - ArculusCreatePIN.View
extension ArculusCreatePIN {
	struct View: SwiftUI.View {
		let store: StoreOf<ArculusCreatePIN>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack(spacing: .small2) {
						Image(FactorSourceKind.arculusCard.icon)
							.resizable()
							.frame(.large)

						Text("Create PIN-code")
							.textStyle(.sheetTitle)
							.foregroundStyle(.primaryText)

						Text("Choose a 6-digit PIN for your Arculus Card. You’ll have to use it when signing")
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
			}
		}
	}
}
